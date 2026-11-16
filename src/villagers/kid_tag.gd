class_name KidTag
extends Node
## The village kids and their game of tag (design/game-brief.md, Features item 4; story 004).
## Spawns [code]kids[/code] [Villager]s with the kid sprite, each with a name and a home
## door. By day they come out (on a [code]leave_stagger[/code] stagger after dawn) and play
## tag around the square; at dusk they run home and hide.
##
## Tag is a small state machine over the kids who are out:
## [br]- one kid is [member it]: it runs ([code]kid_speed[/code] x [code]tag_it_speed_mult[/code])
## at the nearest other kid, finding a new street path every [code]tag_repath[/code] s;
## [br]- closer than [code]tag_touch[/code] tiles is a touch: the touched kid becomes
## [member it], stands still for [code]tag_freeze[/code] s, and [signal tag_changed] fires;
## [br]- every other kid, whenever it has nowhere to run, picks the farthest from [member it]
## of [code]tag_candidates[/code] random street tiles within [code]tag_radius[/code] (Manhattan)
## of [code]tag_centre[/code], and runs there.
## [br]If [member it] is not out (at home), the first kid who is out becomes [member it]
## without a signal.
##
## Kids use the villagers' street paths ([member VillagerRoutines.paths]), depth sorting
## ([method VillageScene.add_entity]) and seeded generator ([member VillagerRoutines.rng]).
## They are not in [member VillagerRoutines.villagers]: they never board the train or go
## to an activity. Must come after [VillagerRoutines] in the scene tree, so its setup runs first.
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
## tag_centre, tag_radius  the play area: street tiles within radius of the centre tile
## tag_candidates          tiles a runner considers when picking where to run
## (shared) path_jitter, walk_frames_per_tile, door_inset, leave_stagger
## [/codeblock]

## Emitted when a touch passes "it" on; [param new_it_name] is the kid who is now "it".
## For the village log (stories 005/007), e.g. "little Pip is it!".
signal tag_changed(new_it_name: String)

const VILLAGER_SCENE: PackedScene = preload("res://src/villagers/villager.tscn")
const KID_SPRITE: String = "kid"
const TUNING_KEYS: Array[String] = [
	"kids", "kid_names", "kid_home_doors", "kid_speed", "tag_it_speed_mult", "tag_touch", "tag_freeze",
	"tag_repath", "tag_centre", "tag_radius", "tag_candidates", "path_jitter", "walk_frames_per_tile",
	"door_inset", "leave_stagger",
]
const ACTIVITY_PLAYING: String = "playing tag"
const ACTIVITY_IT: String = "playing tag (it)"
const ACTIVITY_CHASING: String = "playing tag (it), chasing %s"
const ACTIVITY_HEADING_HOME: String = "heading home"

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

var _tuning: Dictionary = {}
var _play_tiles: Array[Vector2i] = []
var _freeze_left: float = 0.0
var _repath_left: float = 0.0


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	var awake: bool = _is_awake()
	if awake:
		_play_tag(delta)
	for kid: Villager in kids:
		if kid.state == Villager.State.HOME:
			if awake:
				kid.timer -= delta
				if kid.timer <= 0.0:
					_leave_home(kid)
			continue
		if not awake and kid.activity != ACTIVITY_HEADING_HOME:
			_go_home(kid)
		kid.step(delta)


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, ["sprites"])
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or _tuning.is_empty():
		get_tree().quit(1)
		return
	var centre: Vector2i = Vector2i(int(_tuning["tag_centre"][0]), int(_tuning["tag_centre"][1]))
	var radius: int = int(_tuning["tag_radius"])
	for tile: Vector2i in routines.paths.walkable_tiles:
		if absi(tile.x - centre.x) + absi(tile.y - centre.y) <= radius:
			_play_tiles.append(tile)
	var names: Array = _tuning["kid_names"]
	var doors: Array = _tuning["kid_home_doors"]
	var sprite_info: Dictionary = layout["sprites"][KID_SPRITE]
	var plaza: Array[Vector2i] = routines.paths.tiles_of(VillagerRoutines.TILE_PLAZA)
	var awake: bool = _is_awake()
	for k: int in int(_tuning["kids"]):
		var kid: Villager = VILLAGER_SCENE.instantiate() as Villager
		var door: Array = doors[k % doors.size()]
		var offset: Vector2 = Vector2(routines.rng.randf() - 0.5, routines.rng.randf() - 0.5) * _t("path_jitter")
		kid.setup(village, sprite_info, names[k % names.size()], KID_SPRITE, Vector2i(int(door[0]), int(door[1])),
			offset, _t("walk_frames_per_tile"))
		village.add_entity(kid)
		kids.append(kid)
		# A lively start: in the day every kid is already out in the square.
		if awake:
			kid.place(Vector2(plaza[routines.rng.randi_range(0, plaza.size() - 1)]) + Vector2(0.5, 0.5) + offset)
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
	set_physics_process(true)


func _is_awake() -> bool:
	return clock.time >= clock.wake_time and clock.time < clock.home_time


func _play_tag(delta: float) -> void:
	var playing: Array[Villager] = []
	for kid: Villager in kids:
		if kid.visible:
			playing.append(kid)
	if playing.is_empty():
		return
	if it == null or not it.visible:
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
