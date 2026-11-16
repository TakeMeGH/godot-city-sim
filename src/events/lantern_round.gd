class_name LanternRound
extends VillageEvent
## Evening lantern round (story 005): at dusk an elder walks to each unlit lantern in
## order (by i + j, back of the village first) and lights it with
## [method Lantern.set_lit], pausing [code]lantern_light_seconds[/code] at
## each, then goes home. The elder is the free visible elder nearest the first lantern,
## else an elder at home, who steps out of their door.
##
## Phases: WALK -> LIGHT -> WALK ... -> end. If the round takes longer than
## [code]lantern_round_timeout[/code] s the remaining lanterns light at once and the
## elder is let go. At dawn ([method cut_short]) the elder is let go at once. Every way
## the round ends writes an end line to the log (all lit / timed out / cut by dawn).
##
## Timing (story 008, 20x20 map, 21 lanterns): the walk in lighting order is about
## 201 tiles, so at [code]walk_speed * lantern_walk_mult[/code] tiles/s plus
## [code]lantern_light_seconds[/code] per lantern the round must fit inside the night
## ([code](1 - home_time + wake_time) * day_seconds[/code], 117.6 s); the timeout must be
## shorter than the night too, or dawn cuts the round first ([EventDirector] checks it).
##
## Tuning keys (seconds, multiplier): lantern_walk_mult, lantern_light_seconds,
## lantern_round_timeout, (shared) walk_speed, door_inset.

enum Phase { WALK, LIGHT }

const TRANSITIONS: Dictionary = {
	Phase.WALK: [Phase.LIGHT],
	Phase.LIGHT: [Phase.WALK],
}
const ACTIVITY: String = "lighting the lanterns"

var _phase: Phase = Phase.WALK
var _elder: Villager = null
## Lantern indices (into [member VillageScene.lanterns]) still to light, in order.
var _queue: Array[int] = []
var _current: int = -1
var _elapsed: float = 0.0


## Picks and holds the elder and sends them to the first unlit lantern. False (holding
## nobody) when every lantern is already lit or no elder is available.
func start() -> bool:
	var d: EventDirector = _director
	for index: int in d.lantern_order():
		if not d.village.lanterns[index].is_lit:
			_queue.append(index)
	if _queue.is_empty():
		return false
	var first: Vector2 = Vector2(d.lantern_spot(_queue[0])) + Vector2(0.5, 0.5)
	_elder = d.nearest_free(first, _is_elder)
	if _elder == null:
		_elder = _elder_at_home()
		if _elder == null:
			return false
		_elder.visible = true
		_elder.place(Vector2(_elder.home_door) + Vector2(0.5, d.t("door_inset")))
		_elder.state = Villager.State.IDLE
	hold(_elder)
	d.log_line("Old %s starts the evening lantern round" % _elder.villager_name)
	_next()
	return true


## Counts the pause at each lantern and the round's time limit.
func update(delta: float) -> void:
	if done:
		return
	phase_time += delta
	_elapsed += delta
	if _elapsed > _director.t("lantern_round_timeout"):
		for index: int in _queue:
			_director.village.lanterns[index].set_lit(true)
		if _current >= 0:
			_director.village.lanterns[_current].set_lit(true)
		_queue.clear()
		_director.log_line("The last lanterns are lit. Old %s heads home" % _elder.villager_name)
		finish()
		return
	if _phase == Phase.LIGHT and phase_time >= _director.t("lantern_light_seconds"):
		_next()


func _next() -> void:
	if done:
		return
	if _queue.is_empty():
		_director.log_line("Every lantern is lit. Old %s heads home" % _elder.villager_name)
		finish()
		return
	_current = _queue.pop_front()
	if _phase != Phase.WALK:
		_go(Phase.WALK)
	_elder.activity = ACTIVITY
	_director.walk_to(_elder, _director.lantern_spot(_current),
		_director.t("walk_speed") * _director.t("lantern_walk_mult"), _on_reached.bind(_current))


## Dawn: the elder leaves the round unfinished (the director puts every lantern out).
func cut_short() -> void:
	if done:
		return
	if _elder != null:
		_director.log_line("Day breaks. Old %s leaves the lantern round and heads home" % _elder.villager_name)
	super.cut_short()


func _on_reached(index: int) -> void:
	if not holds(_elder) or index != _current:
		return
	_director.village.lanterns[index].set_lit(true)
	_current = -1
	_go(Phase.LIGHT)
	var reach: Array[int] = [Villager.BACK_FRAME_OFFSET]
	_elder.linger(ACTIVITY, 0.0, reach)


func _go(to: Phase) -> void:
	_check_transition(TRANSITIONS, _phase, to)
	_phase = to


func _is_elder(villager: Villager) -> bool:
	return villager.type == VillagerRoutines.TYPE_ELDER


func _elder_at_home() -> Villager:
	for villager: Villager in _director.routines.villagers:
		if villager.type == VillagerRoutines.TYPE_ELDER and villager.state == Villager.State.HOME \
				and villager.lock == null:
			return villager
	return null
