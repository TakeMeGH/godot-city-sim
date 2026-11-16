class_name VillagerRoutines
extends Node
## The residents' daily routines (design/game-brief.md, Features item 3; story 003).
## Spawns [code]residents[/code] [Villager]s, each with a name and a home door, and
## runs their day on the physics step:
## [br]- after dawn they leave home on a stagger; after dusk they walk home and hide;
## [code]night_watch[/code] ninjas do the opposite (out at night, home by day);
## [br]- awake, each picks training, the shop, the station platform, the square or a
## walk by its type's [code]activity_weights[/code], walks there by the shortest
## street path ([VillagePaths]) and lingers [code]idle_min[/code]..[code]idle_max[/code] s;
## [br]- at the platform they wait, board on [signal Train.departing] (hidden, state
## [code]AWAY[/code]) and step off on [signal Train.arrived], stand a moment, then carry on.
##
## All randomness comes from one [RandomNumberGenerator] seeded with [code]villager_seed[/code].
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (times in seconds,
## speeds in tiles per second, positions in tiles):
## [codeblock]
## villager_seed                      seed of the villagers' random generator
## residents, villager_names, villager_types
##                                    count; names and types, used in order and repeated
## night_watch                        how many ninjas keep the night watch
## walk_speed, walk_frames_per_tile   walking speed; walk cycle frame swaps per tile
## idle_min, idle_max                 linger at an activity
## activity_weights                   per type: train, shop, platform, plaza, wander
## walk_tiles                         tile names villagers may walk on
## leave_stagger, dusk_stagger        random delay before leaving home / heading home
## start_outside_chance               share of awake villagers already outside at start
## start_idle_min, start_idle_max     their first linger
## watch_out_before, watch_home_after night watch is out from home_time - this to wake_time + this
## watch_idle_min, watch_idle_max     night watch linger at each street spot
## wait_min, wait_max                 how long a villager waits for a train before giving up
## alight_wait, alight_stagger        passengers stand this long after the train arrives, plus k * stagger
## path_jitter                        size of each villager's offset from tile centres
## door_inset                         how far in front of the house edge a villager appears / vanishes
## train_pose_seconds                 time per training pose
## train_platform_min_i               (shared with Train) platform tiles with smaller i are not used
## [/codeblock]

const VILLAGER_SCENE: PackedScene = preload("res://src/villagers/villager.tscn")
const TUNING_KEYS: Array[String] = [
	"villager_seed", "residents", "villager_names", "villager_types", "night_watch", "walk_speed",
	"walk_frames_per_tile", "idle_min", "idle_max", "activity_weights", "walk_tiles", "leave_stagger",
	"dusk_stagger", "start_outside_chance", "start_idle_min", "start_idle_max", "watch_out_before",
	"watch_home_after", "watch_idle_min", "watch_idle_max", "wait_min", "wait_max", "alight_wait",
	"alight_stagger", "path_jitter", "door_inset", "train_pose_seconds", "train_platform_min_i",
]
const LAYOUT_KEYS: Array[String] = ["map", "tile_legend", "doors", "sprites"]
## Activity keys of [code]activity_weights[/code], in the order they are rolled.
const ACTIVITIES: Array[String] = ["train", "shop", "platform", "plaza", "wander"]
const DOOR_HOME: String = "home"
const DOOR_SHOP: String = "shop"
const TILE_STREET: String = "dirt"
const TILE_PLAZA: String = "cobble"
const TILE_PLATFORM: String = "platform"
const TILE_SAND: String = "sand"
const TYPE_NINJA: String = "ninja"
const TYPE_ELDER: String = "elder"

## The village the villagers live in.
@export var village: VillageScene
## The day clock that drives wake-up and home time.
@export var clock: DayClock
## The train they board and step off.
@export var train: Train

## Every resident, in spawn order.
var villagers: Array[Villager] = []
## Walkable tiles and shortest paths. Valid once the village is ready.
var paths: VillagePaths

var _tuning: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shop_doors: Array[Vector2i] = []
var _platform_tiles: Array[Vector2i] = []


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	for villager: Villager in villagers:
		match villager.state:
			Villager.State.HOME:
				if _is_awake(villager):
					villager.timer -= delta
					if villager.timer <= 0.0:
						_leave_home(villager)
			Villager.State.AWAY:
				pass
			_:
				villager.step(delta)
				if villager.lock == null and villager.state in [Villager.State.IDLE, Villager.State.WAIT]:
					villager.timer -= delta
					if villager.timer <= 0.0:
						next_activity(villager)


## The visible villager nearest to tile point [param tile_point], or null if none.
## With [param filter] (a [code]func(v: Villager) -> bool[/code]) only villagers it
## accepts count.
## Example: [code]routines.find_nearest(Vector2(4.5, 3.5), func(v: Villager) -> bool: return v.lock == null)[/code]
func find_nearest(tile_point: Vector2, filter: Callable = Callable()) -> Villager:
	var best: Villager = null
	var best_distance: float = INF
	for villager: Villager in villagers:
		if not villager.visible or (filter.is_valid() and not filter.call(villager)):
			continue
		var distance: float = villager.tile_pos.distance_squared_to(tile_point)
		if distance < best_distance:
			best_distance = distance
			best = villager
	return best


## Sends [param villager] on to its next activity (or home, when it is not its time
## to be out). Does nothing while the villager is locked.
func next_activity(villager: Villager) -> void:
	if villager.lock != null:
		return
	if not _is_awake(villager):
		_go_home(villager)
		return
	if villager.night_watch:
		villager.activity = "on night watch"
		_go_to(villager, _pick(paths.tiles_of(TILE_STREET)), func() -> void:
			villager.linger("on night watch", _range("watch_idle_min", "watch_idle_max")))
		return
	var weights: Dictionary = _tuning["activity_weights"][villager.type]
	var roll: float = _rng.randf()
	var total: float = 0.0
	var choice: String = ACTIVITIES[-1]
	for activity: String in ACTIVITIES:
		total += float(weights[activity])
		if roll < total:
			choice = activity
			break
	match choice:
		"train":
			villager.activity = "off to train"
			var poses: Array[int] = Villager.TRAINING_POSES if villager.has_combat_poses() else Villager.WALK_CYCLE
			_go_to(villager, _pick(paths.tiles_of(TILE_SAND)), func() -> void:
				villager.linger("training", _range("idle_min", "idle_max"), poses, _t("train_pose_seconds")))
		"shop":
			villager.activity = "going shopping"
			_go_to(villager, _pick(_shop_doors), func() -> void:
				villager.linger("shopping", _range("idle_min", "idle_max")))
		"platform":
			villager.activity = "going to the station"
			var arrive_platform: Callable = func() -> void:
				if _is_awake(villager):
					villager.wait("waiting for the train", _range("wait_min", "wait_max"))
				else:
					next_activity(villager)
			_go_to(villager, _pick(_platform_tiles), arrive_platform)
		"plaza":
			villager.activity = "strolling to the square"
			var label: String = "resting in the square" if villager.type == TYPE_ELDER else "chatting in the square"
			_go_to(villager, _pick(paths.tiles_of(TILE_PLAZA)), func() -> void:
				villager.linger(label, _range("idle_min", "idle_max")))
		_:
			villager.activity = "taking a walk"
			_go_to(villager, _pick(paths.tiles_of(TILE_STREET)), func() -> void:
				villager.linger("looking around", _range("idle_min", "idle_max")))


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, LAYOUT_KEYS)
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or _tuning.is_empty():
		get_tree().quit(1)
		return
	_rng.seed = int(_tuning["villager_seed"])
	paths = VillagePaths.new(layout["map"], layout["tile_legend"], _tuning["walk_tiles"])
	var min_i: int = int(_tuning["train_platform_min_i"])
	for tile: Vector2i in paths.tiles_of(TILE_PLATFORM):
		if tile.x >= min_i:
			_platform_tiles.append(tile)
	var home_doors: Array[Vector2i] = []
	var doors: Array = layout["doors"]
	for door: Dictionary in doors:
		var door_tile: Vector2i = Vector2i(int(door["door"][0]), int(door["door"][1]))
		if door["kind"] == DOOR_HOME:
			home_doors.append(door_tile)
		elif door["kind"] == DOOR_SHOP:
			_shop_doors.append(door_tile)
	_spawn(layout["sprites"], home_doors)
	clock.dawn.connect(_on_dawn)
	clock.dusk.connect(_on_dusk)
	train.arrived.connect(_on_train_arrived)
	train.departing.connect(_on_train_departing)
	set_physics_process(true)


func _spawn(sprites: Dictionary, home_doors: Array[Vector2i]) -> void:
	var names: Array = _tuning["villager_names"]
	var types: Array = _tuning["villager_types"]
	var jitter: float = _t("path_jitter")
	var ninjas: Array[Villager] = []
	for k: int in int(_tuning["residents"]):
		var villager: Villager = VILLAGER_SCENE.instantiate() as Villager
		var villager_type: String = types[k % types.size()]
		var offset: Vector2 = Vector2(_rng.randf() - 0.5, _rng.randf() - 0.5) * jitter
		villager.setup(village, sprites[villager_type], names[k % names.size()], villager_type,
			home_doors[k % home_doors.size()], offset, _t("walk_frames_per_tile"))
		villager.visible = false
		villager.place(Vector2(villager.home_door) + Vector2(0.5, _t("door_inset")))
		village.add_entity(villager)
		villagers.append(villager)
		if villager_type == TYPE_NINJA:
			ninjas.append(villager)
	for k: int in mini(int(_tuning["night_watch"]), ninjas.size()):
		var watcher: Villager = ninjas.pop_at(_rng.randi_range(0, ninjas.size() - 1))
		watcher.night_watch = true
	# A lively start: most villagers who are awake are already out.
	for villager: Villager in villagers:
		if _is_awake(villager) and _rng.randf() < _t("start_outside_chance"):
			villager.visible = true
			villager.place(Vector2(_pick(paths.walkable_tiles)) + Vector2(0.5, 0.5) + villager.offset_in_tile)
			villager.linger("looking around", _range("start_idle_min", "start_idle_max"))
		else:
			villager.timer = _rng.randf() * _t("leave_stagger")


func _is_awake(villager: Villager) -> bool:
	var t: float = clock.time
	if villager.night_watch:
		return t >= clock.home_time - _t("watch_out_before") or t < clock.wake_time + _t("watch_home_after")
	return t >= clock.wake_time and t < clock.home_time


func _leave_home(villager: Villager) -> void:
	var door: Vector2 = Vector2(villager.home_door)
	villager.visible = true
	villager.place(door + Vector2(0.5, _t("door_inset")))
	villager.activity = "heading out"
	var points: Array[Vector2] = [door + Vector2(0.5, 0.5) + villager.offset_in_tile]
	villager.follow(points, _t("walk_speed"), func() -> void: next_activity(villager))


func _go_home(villager: Villager) -> void:
	villager.activity = "heading home"
	var door: Vector2 = Vector2(villager.home_door)
	var into_door: Vector2 = door + Vector2(0.5, _t("door_inset"))
	var go_indoors: Callable = func() -> void:
		villager.disappear(Villager.State.HOME, "at home")
		villager.timer = _rng.randf() * _t("leave_stagger")
	_go_to(villager, villager.home_door, go_indoors, into_door)


## Walks [param villager] by the shortest path to [param tile] (its own offset from the
## tile centre), then optionally on to [param extra], then calls [param on_arrive].
func _go_to(villager: Villager, tile: Vector2i, on_arrive: Callable, extra: Variant = null) -> void:
	var from: Vector2i = Vector2i(villager.tile_pos.floor())
	if not paths.is_walkable(from):
		from = villager.home_door
	var points: Array[Vector2] = []
	for step: Vector2i in paths.find_path(from, tile):
		points.append(Vector2(step) + Vector2(0.5, 0.5) + villager.offset_in_tile)
	if extra != null:
		points.append(extra)
	villager.follow(points, _t("walk_speed"), on_arrive)


func _on_dawn() -> void:
	for villager: Villager in villagers:
		if villager.state == Villager.State.HOME:
			villager.timer = _rng.randf() * _t("leave_stagger")


func _on_dusk() -> void:
	for villager: Villager in villagers:
		if villager.lock == null and villager.state in [Villager.State.IDLE, Villager.State.WAIT] \
				and not _is_awake(villager):
			villager.timer = minf(villager.timer, _rng.randf() * _t("dusk_stagger"))


func _on_train_arrived(platform_tiles: Array[Vector2i]) -> void:
	var k: int = 0
	for villager: Villager in villagers:
		if villager.state != Villager.State.AWAY:
			continue
		var tile: Vector2i = platform_tiles[k % platform_tiles.size()]
		villager.visible = true
		villager.place(Vector2(tile) + Vector2(0.5, 0.5) + villager.offset_in_tile)
		villager.facing_back = false
		villager.linger("just off the train", _t("alight_wait") + k * _t("alight_stagger"))
		k += 1


func _on_train_departing() -> void:
	for villager: Villager in villagers:
		if villager.state == Villager.State.WAIT and villager.visible and villager.lock == null:
			villager.disappear(Villager.State.AWAY, "away on the train")


func _pick(tiles: Array[Vector2i]) -> Vector2i:
	return tiles[_rng.randi_range(0, tiles.size() - 1)]


func _range(min_key: String, max_key: String) -> float:
	return _rng.randf_range(_t(min_key), maxf(_t(min_key), _t(max_key)))


func _t(key: String) -> float:
	return float(_tuning[key])


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("VillagerRoutines: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("VillagerRoutines: %s has no '%s'" % [path, key])
			return {}
	return data
