class_name EventDirector
extends Node
## Runs the village's small events (design/game-brief.md, Features item 5; story 005).
##
## By day (from [code]wake_time + event_window_after_wake[/code] to
## [code]home_time - event_window_before_home[/code]) it starts one event at a time
## from [code]event_rotation[/code], in order and repeating: the first after
## [code]event_first[/code] s of daytime, each next one [code]event_gap[/code] s after
## the last one ended. An event that cannot start now (e.g. not enough free ninjas)
## is skipped and the next in the rotation is tried after [code]event_retry[/code] s.
## At dusk the running event is cut short ([method VillageEvent.cut_short]) and the
## [LanternRound] starts; at dawn the round (if still going) is cut short and every
## lantern goes out. Starting at night, every lantern is already lit.
##
## Events: [SparEvent] ("spar"), [HawkEvent] ("hawk"), [CatEvent] ("cat"),
## [LanternRound] ("lanterns"). Each locks the villagers it uses and releases all of
## them however it ends (see [VillageEvent]).
##
## Must come after [VillagerRoutines] and [VillageLog] in the scene tree, so their
## setup runs first.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (seconds, day fractions):
## [codeblock]
## event_first, event_gap, event_retry           first event, gap after one ends, retry after a skip
## event_window_after_wake, event_window_before_home
##                                               events start only inside this daytime window
## event_rotation                                event kinds, in order, repeated
## (per event) spar_*, hawk_*, cat_*, bird_*, lantern_*   see each event's doc
## (shared) walk_speed, run_speed, door_inset
## [/codeblock]
##
## Command-line user arg (after [code]--[/code]) for repeatable screenshots:
## [codeblock]
## godot --path . -- --event=spar   # start that event at once (spar, hawk, cat, lanterns)
## [/codeblock]

const ARG_EVENT: String = "--event="
const KIND_SPAR: String = "spar"
const KIND_HAWK: String = "hawk"
const KIND_CAT: String = "cat"
const KIND_LANTERNS: String = "lanterns"
## Sky critters (the hawk, a flying sparrow) draw over everything in the world.
const SKY_Z_INDEX: int = 100
const TUNING_KEYS: Array[String] = [
	"event_first", "event_gap", "event_retry", "event_window_after_wake", "event_window_before_home",
	"event_rotation", "walk_speed", "run_speed", "door_inset",
	"spar_seconds", "spar_gather_timeout", "spar_watchers", "spar_tile_a", "spar_spot_a", "spar_tile_b",
	"spar_spot_b", "spar_watch_tiles", "spar_watch_speed_mult", "spar_beat", "spar_poses_a", "spar_poses_b",
	"spar_lunge", "spar_lunge_rate", "spar_a_win_chance",
	"hawk_enter_offset", "hawk_exit_offset", "hawk_perch_tile", "hawk_perch_offset", "hawk_speed_in",
	"hawk_speed_out", "hawk_bob", "hawk_bob_rate", "hawk_flap_rate", "hawk_perch_frame", "hawk_collect_tile",
	"hawk_read_seconds", "hawk_perch_timeout",
	"cat_home", "cat_bird_row", "cat_bird_min_i", "cat_bird_max_i", "cat_speed", "cat_pounce_range", "cat_sit_seconds",
	"cat_timeout", "cat_walk_frames_per_tile", "bird_hop_rate", "bird_flap_rate", "bird_fly_velocity",
	"lantern_walk_mult", "lantern_light_seconds", "lantern_round_timeout",
]
const LAYOUT_KEYS: Array[String] = ["sprites", "doors", "placements"]
const DOOR_HOME: String = "home"

## The village the events play out in.
@export var village: VillageScene
## The day clock: daytime window, dusk and dawn.
@export var clock: DayClock
## The villagers' routines: villagers, street paths, seeded generator.
@export var routines: VillagerRoutines
## Where events write their lines.
@export var village_log: VillageLog

## The daytime event under way, or null.
var current: VillageEvent = null
## The evening lantern round under way, or null.
var lantern_round: LanternRound = null
## The tuning data (read by the events through [method t], [method tile], [method point]).
var tuning: Dictionary = {}
## The walkable tile in front of every house door.
var home_doors: Array[Vector2i] = []

var _timer: float = 0.0
var _rotation_index: int = 0
var _sprites: Dictionary = {}
var _lantern_order: Array[int] = []
var _lantern_spots: Array[Vector2i] = []


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	if current != null:
		current.update(delta)
		if current.done:
			current = null
			_timer = t("event_gap")
	elif _in_event_window():
		_timer -= delta
		if _timer <= 0.0:
			var rotation: Array = tuning["event_rotation"]
			var kind: String = rotation[_rotation_index % rotation.size()]
			_rotation_index += 1
			if not start_event(kind):
				_timer = t("event_retry")
	if lantern_round != null:
		lantern_round.update(delta)
		if lantern_round.done:
			lantern_round = null


## Starts the event called [param kind] ("spar", "hawk", "cat" or "lanterns") now,
## whatever the time. False when it cannot: another daytime event (or round) is under
## way, or the event finds nobody to take part.
func start_event(kind: String) -> bool:
	if kind == KIND_LANTERNS:
		return start_lantern_round()
	if current != null:
		return false
	var event: VillageEvent
	match kind:
		KIND_SPAR:
			event = SparEvent.new(self)
		KIND_HAWK:
			event = HawkEvent.new(self)
		KIND_CAT:
			event = CatEvent.new(self)
		_:
			push_error("EventDirector: unknown event '%s'" % kind)
			return false
	if not event.start():
		event.finish()
		return false
	current = event
	return true


## Starts the evening lantern round now. If no elder can do it, every lantern lights at
## once and this returns false.
func start_lantern_round() -> bool:
	if lantern_round != null:
		return false
	var round_event: LanternRound = LanternRound.new(self)
	if not round_event.start():
		round_event.finish()
		set_all_lanterns(true)
		return false
	lantern_round = round_event
	return true


## Lights or puts out every lantern at once.
func set_all_lanterns(lit: bool) -> void:
	for lantern: VillageScene.Lantern in village.lanterns:
		lantern.set_lit(lit)


## True when [param villager] can be picked for an event: out, not held by anything,
## and lingering or walking (not waiting for the train).
func is_free(villager: Villager) -> bool:
	return villager.visible and villager.lock == null \
		and villager.state in [Villager.State.IDLE, Villager.State.WALK]


## The free villager ([method is_free]) nearest [param tile_point], or null. With
## [param filter] ([code]func(v: Villager) -> bool[/code]) only those it accepts.
func nearest_free(tile_point: Vector2, filter: Callable = Callable()) -> Villager:
	return routines.find_nearest(tile_point, func(v: Villager) -> bool:
		return is_free(v) and (not filter.is_valid() or filter.call(v)))


## Walks [param villager] by the shortest street path to [param tile] (its own offset
## from the tile centre) at [param move_speed] tiles/s, then on to [param final_point]
## if it is finite, then calls [param on_arrive]. If there is no path it arrives at once.
func walk_to(villager: Villager, tile: Vector2i, move_speed: float, on_arrive: Callable,
		final_point: Vector2 = Vector2.INF) -> void:
	var from: Vector2i = Vector2i(villager.tile_pos.floor())
	if not routines.paths.is_walkable(from):
		from = villager.home_door
	var points: Array[Vector2] = []
	for step: Vector2i in routines.paths.find_path(from, tile):
		points.append(Vector2(step) + Vector2(0.5, 0.5) + villager.offset_in_tile)
	if final_point.is_finite():
		points.append(final_point)
	villager.follow(points, move_speed, on_arrive)


## Writes [param text] to the village log (with the clock time).
func log_line(text: String) -> void:
	village_log.add_line(text)


## The village's seeded random generator ([member VillagerRoutines.rng]).
func rng() -> RandomNumberGenerator:
	return routines.rng


## Tuning value [param key] as a float.
func t(key: String) -> float:
	return float(tuning[key])


## Tuning value [param key] ([code][i, j][/code]) as a tile.
func tile(key: String) -> Vector2i:
	var pair: Array = tuning[key]
	return Vector2i(int(pair[0]), int(pair[1]))


## Tuning value [param key] ([code][x, y][/code]) as a point (tiles or pixels).
func point(key: String) -> Vector2:
	var pair: Array = tuning[key]
	return Vector2(float(pair[0]), float(pair[1]))


## Tuning value [param key] (a list of numbers) as ints, e.g. sprite frames.
func int_array(key: String) -> Array[int]:
	var values: Array[int] = []
	for value: Variant in tuning[key]:
		values.append(int(value))
	return values


## The part of the world the camera shows, in world pixels.
func view_rect() -> Rect2:
	var camera: Camera2D = village.camera
	var size: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size * 0.5, size)


## Makes a sprite from the layout's table and adds it to the y-sorted world. With
## [param sky] it draws over everything (a flying critter).
func add_critter(sprite_name: String, sky: bool) -> Sprite2D:
	var sprite: Sprite2D = village.create_sprite(sprite_name)
	if sky:
		sprite.z_index = SKY_Z_INDEX
	village.add_entity(sprite)
	return sprite


## Mirrors [param sprite] (made from sheet [param sprite_name]) or not, keeping its
## ground anchor in place.
func face(sprite: Sprite2D, sprite_name: String, mirrored: bool) -> void:
	var info: Dictionary = _sprites[sprite_name]
	sprite.flip_h = mirrored
	sprite.offset.x = -(float(info["w"]) - float(info["ax"])) if mirrored else -float(info["ax"])


## Indices into [member VillageScene.lanterns] in lighting order (by i + j, then i).
func lantern_order() -> Array[int]:
	return _lantern_order


## The walkable tile nearest lantern [param index] (where the lighter stands).
func lantern_spot(index: int) -> Vector2i:
	return _lantern_spots[index]


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, LAYOUT_KEYS)
	tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or tuning.is_empty():
		get_tree().quit(1)
		return
	_sprites = layout["sprites"]
	var doors: Array = layout["doors"]
	for door: Dictionary in doors:
		if door["kind"] == DOOR_HOME:
			home_doors.append(Vector2i(int(door["door"][0]), int(door["door"][1])))
	_setup_lanterns(layout["placements"])
	clock.dusk.connect(_on_dusk)
	clock.dawn.connect(_on_dawn)
	_timer = t("event_first")
	if clock.time < clock.wake_time or clock.time >= clock.home_time:
		set_all_lanterns(true)
	set_physics_process(true)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(ARG_EVENT):
			var kind: String = arg.trim_prefix(ARG_EVENT)
			if not start_event(kind):
				push_warning("EventDirector: %s could not start now" % arg)


## Lantern tile positions come from the layout's placements, in the same order the
## village made [member VillageScene.lanterns].
func _setup_lanterns(placements: Array) -> void:
	var positions: Array[Vector2] = []
	for entry: Dictionary in placements:
		if entry["sprite"] == VillageScene.LANTERN_SPRITE:
			positions.append(Vector2(float(entry["i"]), float(entry["j"])))
	if positions.size() != village.lanterns.size():
		push_error("EventDirector: %d lantern placements but %d lanterns" % [positions.size(), village.lanterns.size()])
		return
	for lantern_pos: Vector2 in positions:
		var best: Vector2i = Vector2i.ZERO
		var best_distance: float = INF
		for walkable: Vector2i in routines.paths.walkable_tiles:
			var distance: float = (Vector2(walkable) + Vector2(0.5, 0.5)).distance_squared_to(lantern_pos)
			if distance < best_distance:
				best_distance = distance
				best = walkable
		_lantern_spots.append(best)
	for k: int in positions.size():
		_lantern_order.append(k)
	_lantern_order.sort_custom(func(a: int, b: int) -> bool:
		var sum_a: float = positions[a].x + positions[a].y
		var sum_b: float = positions[b].x + positions[b].y
		return sum_a < sum_b or (sum_a == sum_b and positions[a].x < positions[b].x))


func _in_event_window() -> bool:
	return clock.time > clock.wake_time + t("event_window_after_wake") \
		and clock.time < clock.home_time - t("event_window_before_home")


func _on_dusk() -> void:
	if current != null:
		current.cut_short()
		if current.done:
			current = null
			_timer = t("event_gap")
	start_lantern_round()


func _on_dawn() -> void:
	if lantern_round != null:
		lantern_round.cut_short()
		lantern_round = null
	set_all_lanterns(false)


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("EventDirector: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("EventDirector: %s has no '%s'" % [path, key])
			return {}
	return data
