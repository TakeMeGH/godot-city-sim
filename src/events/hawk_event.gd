class_name HawkEvent
extends VillageEvent
## Messenger hawk (story 005): a hawk flies in from the top right of the view, lands on
## the station roof, the nearest free ninja (else the nearest free villager) sprints to
## the platform to collect the message, and the hawk flies off to the top left. The
## runner is held until the hawk is gone.
##
## Phases: IN -> PERCH (until the runner has read for [code]hawk_read_seconds[/code],
## or [code]hawk_perch_timeout[/code]) -> OUT -> end. At dusk the runner is let go and
## the hawk flies off at once.
##
## Tuning keys (pixels, pixels per second, seconds, tiles): hawk_enter_offset,
## hawk_exit_offset, hawk_perch_tile, hawk_perch_offset, hawk_speed_in, hawk_speed_out,
## hawk_bob, hawk_bob_rate, hawk_flap_rate, hawk_perch_frame, hawk_collect_tile,
## hawk_read_seconds, hawk_perch_timeout, (shared) run_speed.

enum Phase { IN, PERCH, OUT }

const TRANSITIONS: Dictionary = {
	Phase.IN: [Phase.PERCH, Phase.OUT],
	Phase.PERCH: [Phase.OUT],
}
const SPRITE: String = "hawk"

var _phase: Phase = Phase.IN
var _hawk: Sprite2D = null
var _pos: Vector2 = Vector2.ZERO
var _perch: Vector2 = Vector2.ZERO
var _flight_time: float = 0.0
var _runner: Villager = null
var _runner_ready: bool = false


## Puts the hawk at the top right of the view, heading for the station roof.
func start() -> bool:
	var d: EventDirector = _director
	var view: Rect2 = d.view_rect()
	_pos = Vector2(view.end.x, view.position.y) + d.point("hawk_enter_offset")
	var perch_tile: Vector2 = d.point("hawk_perch_tile")
	_perch = d.village.tile_to_world(perch_tile.x, perch_tile.y) + d.point("hawk_perch_offset")
	_hawk = d.add_critter(SPRITE, true)
	d.log_line("A messenger hawk circles over the village")
	_draw()
	return true


## Flies, perches and leaves.
func update(delta: float) -> void:
	if done:
		return
	phase_time += delta
	_flight_time += delta
	var d: EventDirector = _director
	match _phase:
		Phase.IN:
			if _fly(_perch, d.t("hawk_speed_in"), delta):
				_go(Phase.PERCH)
				d.log_line("The hawk lands on the station roof with a message")
				_call_runner()
		Phase.PERCH:
			if (_runner_ready and phase_time > d.t("hawk_read_seconds")) or phase_time > d.t("hawk_perch_timeout"):
				_go(Phase.OUT)
				if _runner != null:
					d.log_line("%s takes the message. The hawk flies off" % _runner.villager_name)
		Phase.OUT:
			var view: Rect2 = d.view_rect()
			if _fly(view.position + d.point("hawk_exit_offset"), d.t("hawk_speed_out"), delta):
				finish()
				return
	_draw()


func _wind_down() -> void:
	_runner = null
	if _phase != Phase.OUT:
		_go(Phase.OUT)


func _cleanup() -> void:
	if is_instance_valid(_hawk):
		_hawk.queue_free()
	_hawk = null


func _go(to: Phase) -> void:
	_check_transition(TRANSITIONS, _phase, to)
	_phase = to


func _call_runner() -> void:
	var d: EventDirector = _director
	var collect: Vector2i = d.tile("hawk_collect_tile")
	var point: Vector2 = Vector2(collect) + Vector2(0.5, 0.5)
	_runner = d.nearest_free(point, func(v: Villager) -> bool: return v.type == VillagerRoutines.TYPE_NINJA)
	if _runner == null:
		_runner = d.nearest_free(point)
	if _runner == null:
		_runner_ready = true
		return
	hold(_runner)
	d.walk_to(_runner, collect, d.t("run_speed"), _on_runner_arrived.bind(_runner))
	_runner.activity = "sprinting for the message"


func _on_runner_arrived(runner: Villager) -> void:
	if not holds(runner):
		return
	runner.facing_back = true
	runner.linger("reading a message", 0.0)
	_runner_ready = true


## Moves the hawk toward [param target] at [param speed] px/s with a small bob. True on arrival.
func _fly(target: Vector2, speed: float, delta: float) -> bool:
	var to: Vector2 = target - _pos
	var distance: float = to.length()
	if distance < speed * delta:
		_pos = target
		return true
	_pos += to / distance * speed * delta
	_pos.y += sin(_flight_time * _director.t("hawk_bob_rate")) * _director.t("hawk_bob") * delta
	return false


func _draw() -> void:
	if not is_instance_valid(_hawk):
		return
	_hawk.position = _pos
	if _phase == Phase.PERCH:
		_hawk.frame = int(_director.t("hawk_perch_frame"))
	else:
		_hawk.frame = floori(_flight_time * _director.t("hawk_flap_rate")) % _hawk.hframes
	_director.face(_hawk, SPRITE, _phase != Phase.OUT)
