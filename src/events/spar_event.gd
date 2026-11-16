class_name SparEvent
extends VillageEvent
## Sparring match (story 005): the two free ninjas nearest the training ground run
## there, up to [code]spar_watchers[/code] free villagers walk over to watch, the
## fighters trade punches and kicks for [code]spar_seconds[/code], one wins at random
## and everyone goes back to their routine.
##
## Phases: GATHER (fighters running in; ends after [code]spar_gather_timeout[/code] s
## if they never both arrive) -> FIGHT -> end.
##
## Tuning keys (seconds, tiles, tiles per second): spar_seconds, spar_gather_timeout,
## spar_watchers, spar_tile_a, spar_spot_a, spar_tile_b, spar_spot_b, spar_watch_tiles,
## spar_watch_speed_mult, spar_beat, spar_poses_a, spar_poses_b, spar_lunge,
## spar_lunge_rate, spar_a_win_chance, (shared) run_speed, walk_speed.

enum Phase { GATHER, FIGHT }

const TRANSITIONS: Dictionary = {
	Phase.GATHER: [Phase.FIGHT],
}

var _phase: Phase = Phase.GATHER
var _a: Villager = null
var _b: Villager = null
var _spot_a: Vector2 = Vector2.ZERO
var _spot_b: Vector2 = Vector2.ZERO
var _arrived: int = 0


## Picks and holds the two fighters and the watchers and sends them off. False (holding
## nobody) when fewer than two ninjas are free.
func start() -> bool:
	var d: EventDirector = _director
	_spot_a = d.point("spar_spot_a")
	_spot_b = d.point("spar_spot_b")
	_a = d.nearest_free(_spot_a, _is_fighter)
	if _a == null:
		return false
	_b = d.nearest_free(_spot_b, func(v: Villager) -> bool: return v != _a and _is_fighter(v))
	if _b == null:
		return false
	hold(_a)
	hold(_b)
	d.walk_to(_a, d.tile("spar_tile_a"), d.t("run_speed"), _on_fighter_arrived.bind(_a, _b, true), _spot_a)
	d.walk_to(_b, d.tile("spar_tile_b"), d.t("run_speed"), _on_fighter_arrived.bind(_b, _a, false), _spot_b)
	var spots: Array = d.tuning["spar_watch_tiles"]
	var centre: Vector2 = (_spot_a + _spot_b) * 0.5
	for k: int in mini(int(d.t("spar_watchers")), spots.size()):
		var watcher: Villager = d.nearest_free(centre)
		if watcher == null:
			break
		hold(watcher)
		var spot: Vector2i = Vector2i(int(spots[k][0]), int(spots[k][1]))
		d.walk_to(watcher, spot, d.t("walk_speed") * d.t("spar_watch_speed_mult"), _on_watcher_arrived.bind(watcher, k))
	d.log_line("%s challenges %s to a sparring match" % [_a.villager_name, _b.villager_name])
	return true


## Steps the match: waits for both fighters, then the fight, then the result.
func update(delta: float) -> void:
	if done:
		return
	phase_time += delta
	match _phase:
		Phase.GATHER:
			if _arrived >= 2:
				_go(Phase.FIGHT)
				var beat: float = _director.t("spar_beat")
				_a.linger(_a.activity, 0.0, _director.int_array("spar_poses_a"), beat)
				_b.linger(_b.activity, 0.0, _director.int_array("spar_poses_b"), beat)
			elif phase_time > _director.t("spar_gather_timeout"):
				_director.log_line("%s and %s call off the match" % [_a.villager_name, _b.villager_name])
				finish()
		Phase.FIGHT:
			var lunge: float = sin(phase_time * _director.t("spar_lunge_rate")) * _director.t("spar_lunge")
			_a.place(_spot_a + Vector2(lunge, -lunge))
			_b.place(_spot_b + Vector2(-lunge, lunge))
			if phase_time > _director.t("spar_seconds"):
				var winner: Villager = _a if _director.rng().randf() < _director.t("spar_a_win_chance") else _b
				_director.log_line("%s wins the sparring match. The crowd cheers" % winner.villager_name)
				finish()


func _wind_down() -> void:
	_director.log_line("Dusk falls and the sparring match breaks up")
	finish()


func _go(to: Phase) -> void:
	_check_transition(TRANSITIONS, _phase, to)
	_phase = to


func _is_fighter(villager: Villager) -> bool:
	return villager.type == VillagerRoutines.TYPE_NINJA and villager.has_combat_poses()


func _on_fighter_arrived(fighter: Villager, opponent: Villager, mirrored: bool) -> void:
	if not holds(fighter):
		return
	fighter.flipped = mirrored
	fighter.facing_back = false
	fighter.linger("sparring with %s" % opponent.villager_name, 0.0)
	_arrived += 1


func _on_watcher_arrived(watcher: Villager, k: int) -> void:
	if not holds(watcher):
		return
	watcher.facing_back = true
	watcher.flipped = k % 2 == 1
	watcher.linger("watching the match", 0.0)
