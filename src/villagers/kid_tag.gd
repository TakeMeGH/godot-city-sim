class_name KidTag
extends Node
## The village kids and their game of tag (design/game-brief.md, Features items 4 and 13;
## stories 004 and 013).
## Spawns [code]kids[/code] [Villager]s with the kid body, each with a name, a home door and
## a look from the tuning [code]looks[/code] table ([method VillagerRoutines.pick_look]; kids
## of one house never share a look, story 010). By day they come out (on a [code]leave_stagger[/code]
## stagger after dawn) and play tag in the academy yard and the streets next to it; at dusk they
## run home and hide.
##
## Tag is a small state machine over the kids who are out (the kid at the swing is not playing):
## [br]- one kid is [member it]: it runs ([code]kid_speed[/code] x [code]tag_it_speed_mult[/code])
## at the nearest other kid, finding a new street path every [code]tag_repath[/code] s;
## [br]- closer than [code]tag_touch[/code] tiles is a touch: the touched kid becomes
## [member it], stands still for [code]tag_freeze[/code] s, and [signal tag_changed] fires;
## [br]- every other kid, whenever it has nowhere to run, picks the farthest from [member it]
## of [code]tag_candidates[/code] random walk tiles within [code]tag_radius[/code] (Manhattan)
## of [code]tag_centre[/code] (only tiles reachable from the centre), and runs there.
## [br]If [member it] is not out (at home), the first kid who is out becomes [member it]
## without a signal.
##
## The swing (story 013): the layout places one [code]swing_sprite[/code] tree (frame
## [code]swing_rest_frame[/code] at rest). Every [code]swing_gap_min[/code]..[code]swing_gap_max[/code] s
## one kid who is out, not [member it] (so never the frozen kid) and not heading home leaves the
## game ([member swinger]), runs to [code]swing_approach[/code] (a walk-tile point beside the tree)
## and steps onto the seat: it becomes a child of the tree sprite, so it draws in front of the
## tree while the tree sorts with the world. For [code]swing_min[/code]..[code]swing_max[/code] s the
## tree shows [code]swing_frames[/code] in turn, one every [code]swing_frame_seconds[/code], and the
## kid's feet follow the sprite table's [code]seat_points[/code] of the frame shown (plus
## [code]swing_kid_offset[/code] pixels). Then the tree rests, the kid steps off at the approach
## point and plays again. At dusk a kid on the swing gets off first, then runs home.
## [signal swing_taken] fires on each turn, and a share ([code]log_swing_chance[/code]) of turns is
## written to the [VillageLog] ("Pip takes a turn on the swing"), sampled with the seeded generator.
## User arg [code]--swing-now[/code] sends a kid to the swing at once (for screenshots).
##
## Kids use the villagers' street paths ([member VillagerRoutines.paths]), depth sorting
## ([method VillageScene.add_entity]) and seeded generator ([member VillagerRoutines.rng]).
## They are not in [member VillagerRoutines.villagers]: they never board the train or go
## to an activity. Must come after [VillagerRoutines] in the scene tree, so its setup runs first.
##
## Startup checks (push_error, the game carries on): the tag centre must be a walk tile inside the
## [code]yard_lot[/code] lot, every walk tile of that lot (the yard) must be reachable from the
## plaza, the play area must not be empty, the swing tree must be placed exactly once, its
## seat_points must cover every swing frame, and the approach point must be reachable from the
## tag centre. With no tree, nobody swings.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (seconds, tiles per second, tiles):
## [codeblock]
## kids, kid_names         how many kids; their names, used in order and repeated
## kid_home_doors          [i, j] door tiles of their homes, used in order and repeated
## kid_speed               running speed
## tag_it_speed_mult       "it" runs this much faster
## tag_touch               a touch is closer than this
## tag_freeze              the new "it" stands still this long
## tag_repath              "it" finds a new path to its target this often
## tag_centre, tag_radius  the play area: walk tiles within radius of the centre tile
## tag_candidates          tiles a runner considers when picking where to run
## yard_lot                the layout lot holding the academy yard (checked at startup)
## swing_sprite            the swing tree's sprite name (placed in the layout)
## swing_approach          [i, j] walk-tile point where a kid steps on and off the swing
## swing_gap_min/max       time between turns on the swing
## swing_min, swing_max    length of a turn
## swing_frame_seconds     time per swing frame while swinging
## swing_frames            the tree frames shown in turn while swinging (back, forward)
## swing_rest_frame        the tree frame with the swing at rest
## swing_kid_offset        [x, y] pixels from the seat point to the kid's feet
## log_swing_chance        share of turns written to the village log (0..1)
## (shared) path_jitter, walk_frames_per_tile, door_inset, leave_stagger
## [/codeblock]

## Emitted when a touch passes "it" on; [param new_it_name] is the kid who is now "it".
## For the village log (stories 005/007), e.g. "little Pip is it!".
signal tag_changed(new_it_name: String)
## Emitted when a kid sits down on the swing (story 013); [param kid_name] is that kid.
signal swing_taken(kid_name: String)

const VILLAGER_SCENE: PackedScene = preload("res://src/villagers/villager.tscn")
const KID_SPRITE: String = "kid"
const TUNING_KEYS: Array[String] = [
	"kids", "kid_names", "kid_home_doors", "kid_speed", "tag_it_speed_mult", "tag_touch", "tag_freeze",
	"tag_repath", "tag_centre", "tag_radius", "tag_candidates", "path_jitter", "walk_frames_per_tile",
	"door_inset", "leave_stagger", "yard_lot", "swing_sprite", "swing_approach", "swing_gap_min",
	"swing_gap_max", "swing_min", "swing_max", "swing_frame_seconds", "swing_frames", "swing_rest_frame",
	"swing_kid_offset", "log_swing_chance",
]
const LAYOUT_KEYS: Array[String] = ["sprites", "lots"]
## Sprite-table key of the swing tree: per frame, the seat point [x, y] in pixels from its anchor.
const KEY_SEAT_POINTS: String = "seat_points"
const KEY_FRAMES: String = "frames"
## User arg: send a kid to the swing at once (story 013).
const ARG_SWING_NOW: String = "--swing-now"
const ACTIVITY_PLAYING: String = "playing tag"
const ACTIVITY_IT: String = "playing tag (it)"
const ACTIVITY_CHASING: String = "playing tag (it), chasing %s"
const ACTIVITY_HEADING_HOME: String = "heading home"
const ACTIVITY_TO_SWING: String = "running to the swing"
const ACTIVITY_SWINGING: String = "on the swing"
const LOG_SWING: String = "%s takes a turn on the swing"

## The village the kids live in.
@export var village: VillageScene
## The day clock: kids are out from wake_time to home_time.
@export var clock: DayClock
## The villagers' routines, for the street paths and the seeded generator.
@export var routines: VillagerRoutines

## Every kid, in spawn order.
var kids: Array[Villager] = []
## The kid who is "it", or null before anyone has been out.
var it: Villager = null
## The kid running to or sitting on the swing (not playing tag), or null.
var swinger: Villager = null

var _tuning: Dictionary = {}
var _play_tiles: Array[Vector2i] = []
var _freeze_left: float = 0.0
var _repath_left: float = 0.0
## The swing tree sprite (null when the layout has none: nobody swings).
var _tree: Sprite2D = null
## Swing tree frame -> seat point (pixels from the tree's anchor).
var _seat_points: Array[Vector2] = []
var _swing_frames: Array[int] = []
## True while [member swinger] sits on the seat (a child of the tree).
var _on_seat: bool = false
var _swing_left: float = 0.0
var _swing_frame_left: float = 0.0
var _swing_frame_index: int = 0
## Seconds until the next kid goes to the swing.
var _next_swing: float = 0.0
## The village log, for the sampled swing lines (null when the scene has none).
var _log: VillageLog = null


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	var awake: bool = _is_awake()
	if awake:
		_play_tag(delta)
		_update_swing(delta)
	for kid: Villager in kids:
		if kid.state == Villager.State.HOME:
			if awake:
				kid.timer -= delta
				if kid.timer <= 0.0:
					_leave_home(kid)
			continue
		if not awake and kid.activity != ACTIVITY_HEADING_HOME:
			if kid == swinger:
				_end_swing()
			_go_home(kid)
		kid.step(delta)


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, LAYOUT_KEYS)
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or _tuning.is_empty():
		get_tree().quit(1)
		return
	var centre: Vector2i = _tile_of_key("tag_centre")
	var radius: int = int(_tuning["tag_radius"])
	var centre_ok: bool = routines.paths.is_walkable(centre)
	for tile: Vector2i in routines.paths.walkable_tiles:
		if absi(tile.x - centre.x) + absi(tile.y - centre.y) > radius:
			continue
		if not centre_ok or tile == centre or not routines.paths.find_path(centre, tile).is_empty():
			_play_tiles.append(tile)
	_check_yard(layout, centre)
	_setup_swing(layout, centre)
	var names: Array = _tuning["kid_names"]
	var doors: Array = _tuning["kid_home_doors"]
	var sprite_info: Dictionary = layout["sprites"][KID_SPRITE]
	var start_tiles: Array[Vector2i] = _play_tiles if not _play_tiles.is_empty() \
		else routines.paths.tiles_of(VillagerRoutines.TILE_PLAZA)
	var awake: bool = _is_awake()
	for k: int in int(_tuning["kids"]):
		var kid: Villager = VILLAGER_SCENE.instantiate() as Villager
		var door: Array = doors[k % doors.size()]
		var door_tile: Vector2i = Vector2i(int(door[0]), int(door[1]))
		var offset: Vector2 = Vector2(routines.rng.randf() - 0.5, routines.rng.randf() - 0.5) * _t("path_jitter")
		var housemates: Array[String] = []
		for other: Villager in kids:
			if other.home_door == door_tile:
				housemates.append(other.look)
		var look: String = routines.pick_look(KID_SPRITE, housemates)
		var info: Dictionary = layout["sprites"].get(look, sprite_info)
		kid.setup(village, info, names[k % names.size()], KID_SPRITE, door_tile,
			offset, _t("walk_frames_per_tile"), look)
		village.add_entity(kid)
		kids.append(kid)
		# A lively start: in the day every kid is already out in the play area by the academy.
		if awake:
			kid.place(Vector2(start_tiles[routines.rng.randi_range(0, start_tiles.size() - 1)]) + Vector2(0.5, 0.5) + offset)
			kid.state = Villager.State.IDLE
			kid.activity = ACTIVITY_PLAYING
		else:
			kid.visible = false
			kid.place(Vector2(kid.home_door) + Vector2(0.5, _t("door_inset")))
			kid.disappear(Villager.State.HOME, "at home")
			kid.timer = routines.rng.randf() * _t("leave_stagger")
	if not kids.is_empty():
		it = kids[0]
	# The first "it" counts too, so the runners scatter before the chase starts.
	_freeze_left = _t("tag_freeze")
	_next_swing = 0.0 if ARG_SWING_NOW in OS.get_cmdline_user_args() else _swing_gap()
	set_physics_process(true)


## Startup check of the yard (story 013): the tag centre must be a walk tile inside the
## [code]yard_lot[/code] lot, every walk tile of that lot must be reachable from the plaza, and
## the play area must not be empty. Logs every problem with push_error.
func _check_yard(layout: Dictionary, centre: Vector2i) -> void:
	if not routines.paths.is_walkable(centre):
		push_error("KidTag: tuning 'tag_centre' %s is not a walk tile, so the play area is not checked for reach" % centre)
	if _play_tiles.is_empty():
		push_error("KidTag: no walk tile within 'tag_radius' of 'tag_centre' %s; nobody can play tag" % centre)
	var lot_name: String = str(_tuning["yard_lot"])
	var lots: Dictionary = layout["lots"]
	if not lots.has(lot_name):
		push_error("KidTag: the layout has no lot '%s' (tuning 'yard_lot')" % lot_name)
		return
	var lot: Dictionary = lots[lot_name]
	var rect: Rect2i = Rect2i(int(lot["i"]), int(lot["j"]), int(lot["w"]), int(lot["h"]))
	if not rect.has_point(centre):
		push_error("KidTag: tuning 'tag_centre' %s is outside the yard lot '%s' %s" % [centre, lot_name, rect])
	var plaza_tiles: Array[Vector2i] = routines.paths.tiles_of(VillagerRoutines.TILE_PLAZA)
	var yard_size: int = 0
	for j: int in range(rect.position.y, rect.end.y):
		for i: int in range(rect.position.x, rect.end.x):
			var tile: Vector2i = Vector2i(i, j)
			if not routines.paths.is_walkable(tile):
				continue
			yard_size += 1
			if not plaza_tiles.is_empty() and routines.paths.find_path(plaza_tiles[0], tile).is_empty():
				push_error("KidTag: yard tile %s of lot '%s' cannot be reached from the plaza" % [tile, lot_name])
	if yard_size == 0:
		push_error("KidTag: the yard lot '%s' %s has no walk tiles" % [lot_name, rect])


## Finds the swing tree and its seat points, and checks them (story 013). Logs every problem
## with push_error; with no tree, nobody swings.
func _setup_swing(layout: Dictionary, centre: Vector2i) -> void:
	_log = _find_log()
	if _log == null:
		push_warning("KidTag: no VillageLog beside KidTag, so swing turns are not logged")
	var sprite_name: String = str(_tuning["swing_sprite"])
	var trees: Array[Sprite2D] = village.placed_sprites(sprite_name)
	if trees.size() != 1:
		push_error("KidTag: the layout places the swing tree '%s' %d times (needs exactly 1)" % [sprite_name, trees.size()])
	var info: Dictionary = layout["sprites"].get(sprite_name, {})
	var pairs: Array = info.get(KEY_SEAT_POINTS, [])
	for pair: Array in pairs:
		_seat_points.append(Vector2(float(pair[0]), float(pair[1])))
	var frame_count: int = int(info.get(KEY_FRAMES, 0))
	var frames: Array = _tuning["swing_frames"]
	for frame: Variant in frames:
		_swing_frames.append(int(frame))
	var swing_ok: bool = not trees.is_empty() and not _swing_frames.is_empty()
	if _swing_frames.is_empty():
		push_error("KidTag: tuning 'swing_frames' is empty")
	for frame: int in _swing_frames + [int(_tuning["swing_rest_frame"])]:
		if frame < 0 or frame >= frame_count or frame >= _seat_points.size():
			push_error("KidTag: swing frame %d has no picture or no seat point in '%s' (%d frames, %d seat_points)"
				% [frame, sprite_name, frame_count, _seat_points.size()])
			swing_ok = false
	var approach: Vector2i = _tile_of_key("swing_approach")
	if not routines.paths.is_walkable(approach) or (approach != centre and routines.paths.find_path(centre, approach).is_empty()):
		push_error("KidTag: tuning 'swing_approach' tile %s cannot be reached from 'tag_centre' %s" % [approach, centre])
		swing_ok = false
	if swing_ok:
		_tree = trees[0]
		_tree.frame = int(_tuning["swing_rest_frame"])


## The [VillageLog] among KidTag's siblings, or null.
func _find_log() -> VillageLog:
	for node: Node in get_parent().get_children():
		if node is VillageLog:
			return node as VillageLog
	return null


func _is_awake() -> bool:
	return clock.time >= clock.wake_time and clock.time < clock.home_time


func _play_tag(delta: float) -> void:
	var playing: Array[Villager] = []
	for kid: Villager in kids:
		if kid.visible and kid != swinger:
			playing.append(kid)
	if playing.is_empty():
		return
	if it == null or not it.visible or it == swinger:
		it = playing[0]
	_freeze_left = maxf(0.0, _freeze_left - delta)
	_repath_left -= delta
	for kid: Villager in playing:
		if kid == it:
			_chase(kid, playing)
		elif kid.path.is_empty():
			_run_away(kid)


func _chase(chaser: Villager, playing: Array[Villager]) -> void:
	if _freeze_left > 0.0:
		chaser.activity = ACTIVITY_IT
		return
	var target: Villager = null
	var best: float = INF
	for kid: Villager in playing:
		var distance: float = kid.tile_pos.distance_to(chaser.tile_pos)
		if kid != chaser and distance < best:
			best = distance
			target = kid
	if target == null:
		chaser.activity = ACTIVITY_IT
		return
	if best < _t("tag_touch"):
		it = target
		_freeze_left = _t("tag_freeze")
		_repath_left = 0.0
		target.place(target.tile_pos)
		target.state = Villager.State.IDLE
		target.activity = ACTIVITY_IT
		chaser.activity = ACTIVITY_PLAYING
		tag_changed.emit(target.villager_name)
		return
	chaser.activity = ACTIVITY_CHASING % target.villager_name
	if _repath_left > 0.0 and not chaser.path.is_empty():
		return
	_repath_left = _t("tag_repath")
	var points: Array[Vector2] = []
	for step: Vector2i in routines.paths.find_path(Vector2i(chaser.tile_pos.floor()), Vector2i(target.tile_pos.floor())):
		points.append(Vector2(step) + Vector2(0.5, 0.5))
	if points.is_empty():
		points.append(target.tile_pos)
	else:
		points[-1] = target.tile_pos
	chaser.follow(points, _t("kid_speed") * _t("tag_it_speed_mult"), Callable())


func _run_away(runner: Villager) -> void:
	runner.activity = ACTIVITY_PLAYING
	if _play_tiles.is_empty():
		return
	var best_tile: Vector2i = runner.home_door
	var best_score: float = -1.0
	for k: int in int(_tuning["tag_candidates"]):
		var tile: Vector2i = _play_tiles[routines.rng.randi_range(0, _play_tiles.size() - 1)]
		var score: float = Vector2(tile).distance_to(it.tile_pos) if it != null else routines.rng.randf()
		if score > best_score:
			best_score = score
			best_tile = tile
	var points: Array[Vector2] = []
	for step: Vector2i in routines.paths.find_path(Vector2i(runner.tile_pos.floor()), best_tile):
		points.append(Vector2(step) + Vector2(0.5, 0.5) + runner.offset_in_tile)
	if not points.is_empty():
		runner.follow(points, _t("kid_speed"), Callable())


## The swing (story 013): counts down to the next turn, then animates the turn.
func _update_swing(delta: float) -> void:
	if _tree == null:
		return
	if swinger == null:
		_next_swing -= delta
		if _next_swing <= 0.0:
			_start_swing()
		return
	if not _on_seat:
		return
	_swing_left -= delta
	_swing_frame_left -= delta
	if _swing_frame_left <= 0.0:
		_swing_frame_left += _t("swing_frame_seconds")
		_swing_frame_index = (_swing_frame_index + 1) % _swing_frames.size()
		_show_swing_frame(_swing_frames[_swing_frame_index])
	if _swing_left <= 0.0:
		_end_swing()


## Picks a kid who is out, not "it" (so not frozen) and not heading home, takes it out of the
## game and sends it to the swing's approach point. With nobody free, tries again after a gap.
func _start_swing() -> void:
	var free: Array[Villager] = []
	for kid: Villager in kids:
		if kid.visible and kid != it and kid.state != Villager.State.HOME and kid.activity != ACTIVITY_HEADING_HOME:
			free.append(kid)
	if free.is_empty():
		_next_swing = _swing_gap()
		return
	var kid: Villager = free[routines.rng.randi_range(0, free.size() - 1)]
	swinger = kid
	kid.activity = ACTIVITY_TO_SWING
	var approach: Vector2 = _point("swing_approach")
	var points: Array[Vector2] = []
	for step: Vector2i in routines.paths.find_path(Vector2i(kid.tile_pos.floor()), Vector2i(approach.floor())):
		points.append(Vector2(step) + Vector2(0.5, 0.5))
	points.append(approach)
	kid.follow(points, _t("kid_speed"), _sit_on_swing.bind(kid))


## Seats [param kid] on the swing: it becomes a child of the tree (drawn in front of it) and the
## turn starts. Logs a share of turns.
func _sit_on_swing(kid: Villager) -> void:
	if swinger != kid or _tree == null:
		return
	_on_seat = true
	kid.state = Villager.State.IDLE
	kid.activity = ACTIVITY_SWINGING
	kid.facing_back = false
	kid.flipped = false
	kid.reparent(_tree, false)
	_swing_left = routines.rng.randf_range(_t("swing_min"), _t("swing_max"))
	_swing_frame_index = 0
	_swing_frame_left = _t("swing_frame_seconds")
	_show_swing_frame(_swing_frames[0])
	swing_taken.emit(kid.villager_name)
	if _log != null and routines.rng.randf() < _t("log_swing_chance"):
		_log.add_line(LOG_SWING % kid.villager_name)


## Shows swing tree frame [param frame] and puts the kid's feet on that frame's seat point.
func _show_swing_frame(frame: int) -> void:
	_tree.frame = frame
	if swinger != null and _on_seat:
		swinger.position = _seat_points[frame] + _vec("swing_kid_offset")


## Ends the turn: the tree rests, the kid (if seated) steps off at the approach point back into
## the world and plays on, and the next turn is scheduled.
func _end_swing() -> void:
	var kid: Villager = swinger
	swinger = null
	_next_swing = _swing_gap()
	if _tree != null:
		_tree.frame = int(_tuning["swing_rest_frame"])
	if kid == null:
		return
	kid.activity = ACTIVITY_PLAYING
	if _on_seat:
		_on_seat = false
		kid.reparent(_tree.get_parent(), false)
		kid.place(_point("swing_approach"))
		kid.state = Villager.State.IDLE


func _swing_gap() -> float:
	return routines.rng.randf_range(_t("swing_gap_min"), _t("swing_gap_max"))


func _leave_home(kid: Villager) -> void:
	var door: Vector2 = Vector2(kid.home_door)
	kid.visible = true
	kid.place(door + Vector2(0.5, _t("door_inset")))
	kid.activity = ACTIVITY_PLAYING
	var points: Array[Vector2] = [door + Vector2(0.5, 0.5) + kid.offset_in_tile]
	kid.follow(points, _t("kid_speed"), Callable())


func _go_home(kid: Villager) -> void:
	kid.activity = ACTIVITY_HEADING_HOME
	var from: Vector2i = Vector2i(kid.tile_pos.floor())
	if not routines.paths.is_walkable(from):
		from = kid.home_door
	var points: Array[Vector2] = []
	for step: Vector2i in routines.paths.find_path(from, kid.home_door):
		points.append(Vector2(step) + Vector2(0.5, 0.5) + kid.offset_in_tile)
	points.append(Vector2(kid.home_door) + Vector2(0.5, _t("door_inset")))
	var go_indoors: Callable = func() -> void:
		kid.disappear(Villager.State.HOME, "at home")
		kid.timer = routines.rng.randf() * _t("leave_stagger")
	kid.follow(points, _t("kid_speed"), go_indoors)


func _t(key: String) -> float:
	return float(_tuning[key])


## The point [x, y] in tuning key [param key].
func _vec(key: String) -> Vector2:
	var pair: Array = _tuning[key]
	return Vector2(float(pair[0]), float(pair[1]))


func _point(key: String) -> Vector2:
	return _vec(key)


## The tile holding the tile point in tuning key [param key].
func _tile_of_key(key: String) -> Vector2i:
	return Vector2i(_vec(key).floor())


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("KidTag: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("KidTag: %s has no '%s'" % [path, key])
			return {}
	return data
