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
## [br]- a share ([code]errand_chance[/code]) of the ninjas' trips are run at [code]run_speed[/code];
## a run errand (a walk) ends with a short "catching breath" linger.
##
## [br]- looks (story 010): every resident, kid and the rooftop runner wears a look sheet of
## its body from the [code]looks[/code] table, dealt by [method pick_look] from a seeded
## shuffled deck per body so the village shows many distinct looks, and re-picked so no two
## residents of one house (home door) look the same;
## [br]- roles (story 010): after the residents, each [code]roles[/code] entry spawns
## [code]count[/code] extra residents wearing the role's sheet, with a name, a home door and
## the ordinary routine of the role's [code]base_type[/code] (stories 011-013 will station
## them). Role villagers never keep the night watch.
## [br]- the gate guards (story 011): the [code]guard_role[/code] villagers are stationed at the
## main gate. By day (from [code]wake_time + guard_on_after_wake + k * guard_shift_stagger[/code]
## to [code]home_time[/code]) guard k stands at [code]guard_posts[/code][k] facing down the main
## street, "guarding the gate". From home time [code]guard_night_watch[/code] of them stay on as
## the night watch ("keeping the night watch at the gate") and the rest go home. When the next day
## shift starts, a night guard walks home to rest [code]guard_rest[/code] s, then comes back on
## duty; with [code]guard_swap_daily[/code] the night watch passes to the next guard each evening.
## A guard on duty (walking to its post, at it, or walking home to rest) is held with
## [member Villager.lock] set to this node, so routines and events leave it alone. A guard that is
## held by an event, hidden or on the train when its shift starts is picked up by a later check
## (every [code]guard_check_seconds[/code]).
## [br]- the "gate" activity (story 011): walk the main street to [code]gate_tile[/code], through
## [code]gate_centre[/code] (the passage) to [code]gate_outside[/code], a point beyond the wall and
## off the path grid; linger [code]gate_outside_min[/code]..[code]gate_outside_max[/code] s
## "stepping out of the village" (held with lock, so no event picks a villager outside the
## wall), then walk back in and carry on. User arg [code]--gate-walk-now[/code] sends the free
## villager nearest the gate out at once (for screenshots).
## [br]- the market (story 012): each [code]market_stations[/code] entry is a place for one villager
## of its [code]role[/code] (the k-th villager of a role takes the k-th station of that role). By day,
## from [code]wake_time + station_on_after_wake + n * station_shift_stagger[/code] (n = the station's
## index) to [code]home_time[/code], it stands at the station's [code]stand[/code] point facing its
## [code]look[/code] point with the station's [code]label[/code] ("cooking ramen", "serving tea"...),
## held with [member Villager.lock] like a guard, picked up by the guard check when it was busy, and
## released at home time, when it walks home (the ramen stand closes at dusk: [RamenSteam]).
## [br]- "ramen" activity: while a [code]ramen_role[/code] villager is on duty, walk to a free seat of
## the layout's [code]ramen_seats[/code] (one villager per seat), face [code]ramen_seat_facing[/code]
## and linger [code]ramen_min[/code]..[code]ramen_max[/code] s "eating ramen"; with no free seat or no
## cook, browse instead. "browse" activity: walk to a free [code]browse_spots[/code] spot and linger
## [code]browse_min[/code]..[code]browse_max[/code] s "browsing the market"; with none free, wander.
## [br]- "shop" activity: goes to the market's doors (door kind "market"); the old "shop" doors
## are used only when the layout has no market doors.
## [br]- points off the walk tiles (a seat, the cook's place) are reached through their
## approach tile ([method _approach_tile]): the tile itself when walkable, else the tile in front
## of it (+j, the door convention).
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
## looks                              per body ("ninja", "kunoichi", "elder", "kid"): its look sheet
##                                    names (each must be in the layout's sprite table)
## roles                              per role: sheet, base_type, count, title (title is shown on click);
##                                    role names and home doors continue after the residents'
## walk_speed, walk_frames_per_tile   walking speed; walk cycle frame swaps per tile
## errand_chance, run_speed           share of ninjas' trips run instead of walked; running speed
## breath_min, breath_max             "catching breath" linger after a run errand
## idle_min, idle_max                 linger at an activity
## activity_weights                   per type: train, shop, platform, plaza, hospital, gate, wander (a missing
##                                    key counts as 0)
## train_post_spots                   per training post [stand_i, stand_j, post_i, post_j] (story 014): a
##                                    trainer takes a free post, stands at its spot facing the post
## train_free_tiles                   where trainers train when every post is taken
## memorial_spot                      [stand_i, stand_j, stone_i, stone_j]: where a trainer pauses, facing the stone
## memorial_chance                    share of training trips that pause at the memorial stone first
## memorial_min, memorial_max         that pause ("pausing at the memorial stone")
## hospital_min, hospital_max         linger at the hospital door ("visiting the hospital"; door kind "hospital")
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
## check_walkable_keys, check_inside_keys
##                                    tuning keys holding [i, j] tiles (or lists of them) that the
##                                    startup check requires to be walkable / inside the map
## gate_tile                          the gate's (walkable) path tile
## gate_centre, gate_outside          the passage centre and the point beyond the wall (tile points)
## gate_outside_min, gate_outside_max linger outside the gate
## guard_role, guard_posts            the stationed role; per guard [stand_i, stand_j, look_i, look_j]
## guard_on_after_wake                day shift start after wake_time (day fraction) ...
## guard_shift_stagger                ... plus k times this for guard k
## guard_night_watch                  guards who stay on as the night watch
## guard_rest                         a night guard's rest at home after the watch (s)
## guard_swap_daily                   pass the night watch to the next guard each evening
## guard_check_seconds                how often guard duty is checked and retried (also market stations)
## market_stations                    per station {role, stand: [i, j], look: [i, j], label, heading}
## station_on_after_wake              market shift start after wake_time (day fraction) ...
## station_shift_stagger              ... plus n times this for station n
## ramen_role                         the role whose villager on duty opens the ramen stand
## ramen_seat_facing                  [di, dj]: the way a villager faces on a ramen seat
## ramen_min, ramen_max               "eating ramen" linger
## browse_spots                       per spot [stand_i, stand_j, look_i, look_j] along the market lane
## browse_min, browse_max             "browsing the market" linger
## academy_stations                   (story 013) per station, the same fields as market_stations: the
##                                    teachers' places in the academy yard; they follow the market
##                                    stations in the station list (station n = market count + k)
## [/codeblock]
## The academy teachers (story 013) are stationed exactly like the market: [code]academy_stations[/code]
## join [code]market_stations[/code] in one station list, so a teacher stands at its yard station by
## day ("teaching in the yard"), held with lock, retried by the check when busy, and walks home
## at home time.
## Layout key [code]ramen_seats[/code]: the stand's seat tile points [[i, j], ...].
##
## Startup check (story 008): every door tile must be reachable from the plaza over the walk
## tiles, and every tile in the keys above must be valid; each problem is logged with
## push_error (the unreachable door, or the tuning key that is off) and the game carries on. Story 012 adds
## [method _check_market]: seats, browse spots and stations must be reachable, and each station's
## role must have a villager for it.

const VILLAGER_SCENE: PackedScene = preload("res://src/villagers/villager.tscn")
const TUNING_KEYS: Array[String] = [
	"villager_seed", "residents", "villager_names", "villager_types", "night_watch", "looks", "roles", "walk_speed",
	"errand_chance", "run_speed", "breath_min", "breath_max",
	"walk_frames_per_tile", "idle_min", "idle_max", "activity_weights", "walk_tiles", "leave_stagger",
	"dusk_stagger", "start_outside_chance", "start_idle_min", "start_idle_max", "watch_out_before",
	"watch_home_after", "watch_idle_min", "watch_idle_max", "wait_min", "wait_max", "alight_wait",
	"alight_stagger", "path_jitter", "door_inset", "train_pose_seconds", "train_platform_min_i",
	"check_walkable_keys", "check_inside_keys", "cat_bird_row", "cat_bird_min_i", "cat_bird_max_i",
	"train_post_spots", "train_free_tiles", "memorial_spot", "memorial_chance", "memorial_min", "memorial_max",
	"hospital_min", "hospital_max", "gate_tile", "gate_centre", "gate_outside", "gate_outside_min",
	"gate_outside_max", "guard_role", "guard_posts", "guard_on_after_wake", "guard_shift_stagger",
	"guard_night_watch", "guard_rest", "guard_swap_daily", "guard_check_seconds",
	"market_stations", "station_on_after_wake", "station_shift_stagger", "ramen_role", "ramen_seat_facing",
	"ramen_min", "ramen_max", "browse_spots", "browse_min", "browse_max", "academy_stations",
]
const LAYOUT_KEYS: Array[String] = ["size", "map", "tile_legend", "doors", "sprites"]
const KEY_CAT_ROW: String = "cat_bird_row"
const KEY_CAT_MIN_I: String = "cat_bird_min_i"
const KEY_CAT_MAX_I: String = "cat_bird_max_i"
## Activity keys of [code]activity_weights[/code], in the order they are rolled.
const ACTIVITIES: Array[String] = ["train", "shop", "platform", "plaza", "hospital", "gate", "ramen", "browse", "wander"]
## The activity taken when the roll lands past every weight.
const ACTIVITY_FALLBACK: String = "wander"
const ACTIVITY_TRAIN: String = "train"
const ACTIVITY_HOSPITAL: String = "hospital"
## The walk out through the gate and back (story 011).
const ACTIVITY_GATE: String = "gate"
## User arg: send the free villager nearest the gate out through it at once (story 011).
const ARG_GATE_WALK_NOW: String = "--gate-walk-now"
## Eat at the ramen stand; browse the market lane (story 012).
const ACTIVITY_RAMEN: String = "ramen"
const ACTIVITY_BROWSE: String = "browse"
## Layout key: the ramen stand's seat tile points (story 012).
const KEY_RAMEN_SEATS: String = "ramen_seats"
const STATION_ROLE: String = "role"
const STATION_STAND: String = "stand"
const STATION_LOOK: String = "look"
const STATION_LABEL: String = "label"
const STATION_HEADING: String = "heading"
## A gate guard's shift (story 011): off, the day shift, or the night watch.
enum Shift { NONE, DAY, NIGHT }
const DOOR_HOME: String = "home"
const DOOR_SHOP: String = "shop"
const DOOR_HOSPITAL: String = "hospital"
const DOOR_MARKET: String = "market"
const TILE_STREET: String = "dirt"
const TILE_PLAZA: String = "cobble"
const TILE_PLATFORM: String = "platform"
const TILE_SAND: String = "sand"
const TYPE_NINJA: String = "ninja"
const TYPE_ELDER: String = "elder"
const KEY_LOOKS: String = "looks"
const KEY_ROLES: String = "roles"
const ROLE_SHEET: String = "sheet"
const ROLE_BASE_TYPE: String = "base_type"
const ROLE_COUNT: String = "count"
const ROLE_TITLE: String = "title"

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

## The village's one seeded random generator ([code]villager_seed[/code]). [KidTag] and
## [RooftopDash] draw from it too, so a run with the same seed plays out the same.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _tuning: Dictionary = {}
var _shop_doors: Array[Vector2i] = []
var _hospital_doors: Array[Vector2i] = []
## The market's shop doors (story 012), where the "shop" activity goes.
var _market_doors: Array[Vector2i] = []
## The ramen stand's seats (layout ramen_seats, tile points).
var _seats: Array[Vector2] = []
## Seat index -> the villager on it or walking to it.
var _seat_users: Dictionary = {}
## Browse spot index (into browse_spots) -> the villager at it or walking to it.
var _browse_users: Dictionary = {}
## Every station: market_stations, then academy_stations (story 013).
var _station_list: Array = []
## Stationed villager -> its index into [member _station_list].
var _keepers: Dictionary = {}
## Stationed villagers on duty (walking to their place or at it, held with lock = this node) -> true.
var _station_on: Dictionary = {}
## Training post index (into train_post_spots) -> the villager who took it (story 014).
var _post_users: Dictionary = {}
## Villager -> the activity it goes on to next instead of a weighted roll (after the memorial stone).
var _next_choice: Dictionary = {}
## Per body, its look sheets that exist in the layout's sprite table.
var _looks: Dictionary = {}
## Per body, the looks still to deal before a fresh shuffled deck is added.
var _look_decks: Dictionary = {}
## Every sheet handed out (looks and role sheets), for the startup count.
var _sheets_in_use: Dictionary = {}
var _platform_tiles: Array[Vector2i] = []
## The gate guards (story 011), in post order: guard k stands at guard_posts[k].
var _guards: Array[Villager] = []
## Guard on duty -> its [enum Shift] (it is held with lock = this node).
var _guard_shift: Dictionary = {}
## Night guards walking home to rest, or resting, after the watch -> true.
var _resting: Dictionary = {}
## Index of the first night guard; the night watch is the next guard_night_watch from here.
var _night_start: int = 0
## Whether the last guard check was after home_time (rotates the night watch once per evening).
var _was_evening: bool = false
var _guard_timer: float = 0.0
## Villager outside the gate -> seconds it still lingers there once it stands still.
var _outside: Dictionary = {}


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	_guard_timer -= delta
	if _guard_timer <= 0.0:
		_guard_timer = _t("guard_check_seconds")
		_update_guards()
		_update_stations()
	_tick_outside(delta)
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
	_release_spots(villager)
	if _start_duty_if_due(villager) or _start_station_if_due(villager):
		return
	if not _is_awake(villager):
		_next_choice.erase(villager)
		_go_home(villager)
		return
	if villager.night_watch:
		villager.activity = "on night watch"
		_go_to(villager, _pick(paths.tiles_of(TILE_STREET)), _t("walk_speed"), func() -> void:
			villager.linger("on night watch", _range("watch_idle_min", "watch_idle_max")))
		return
	var choice: String = _next_choice.get(villager, "")
	var after_memorial: bool = not choice.is_empty()
	_next_choice.erase(villager)
	if choice.is_empty():
		choice = _roll_activity(villager.type)
	if choice == ACTIVITY_HOSPITAL and _hospital_doors.is_empty():
		choice = ACTIVITY_FALLBACK
	if choice == ACTIVITY_RAMEN and (not _stand_open() or _free_index(_seats.size(), _seat_users) < 0):
		choice = ACTIVITY_BROWSE
	if choice == ACTIVITY_BROWSE and _free_index(_browse_spots().size(), _browse_users) < 0:
		choice = ACTIVITY_FALLBACK
	var run: bool = villager.type == TYPE_NINJA and rng.randf() < _t("errand_chance")
	var move_speed: float = _t("run_speed") if run else _t("walk_speed")
	match choice:
		ACTIVITY_TRAIN:
			if not after_memorial and rng.randf() < _t("memorial_chance"):
				_visit_memorial(villager)
			else:
				_go_train(villager, run, move_speed)
		ACTIVITY_HOSPITAL:
			villager.activity = "running to the hospital" if run else "going to the hospital"
			var door: Vector2i = _pick(_hospital_doors)
			var visit: Callable = func() -> void:
				villager.linger("visiting the hospital", _range("hospital_min", "hospital_max"))
			_go_to(villager, door, move_speed, visit, Vector2(door) + Vector2(0.5, _t("door_inset")))
		ACTIVITY_GATE:
			villager.activity = "running to the gate" if run else "walking out to the gate"
			var outside: Vector2 = _point("gate_outside") + villager.offset_in_tile
			_go_to(villager, _tile_of_key("gate_tile"), move_speed, func() -> void: _step_out(villager, outside),
				_point("gate_centre"))
		ACTIVITY_RAMEN:
			_go_ramen(villager, run, move_speed)
		ACTIVITY_BROWSE:
			_go_browse(villager, run, move_speed)
		"shop":
			villager.activity = "running to the shop" if run else "going shopping"
			var shops: Array[Vector2i] = _market_doors if not _market_doors.is_empty() else _shop_doors
			_go_to(villager, _pick(shops), move_speed, func() -> void:
				villager.linger("shopping", _range("idle_min", "idle_max")))
		"platform":
			villager.activity = "running to the station" if run else "going to the station"
			var arrive_platform: Callable = func() -> void:
				if _is_awake(villager):
					villager.wait("waiting for the train", _range("wait_min", "wait_max"))
				else:
					next_activity(villager)
			_go_to(villager, _pick(_platform_tiles), move_speed, arrive_platform)
		"plaza":
			villager.activity = "running to the square" if run else "strolling to the square"
			var label: String = "resting in the square" if villager.type == TYPE_ELDER else "chatting in the square"
			_go_to(villager, _pick(paths.tiles_of(TILE_PLAZA)), move_speed, func() -> void:
				villager.linger(label, _range("idle_min", "idle_max")))
		_:
			if run:
				villager.activity = "running an errand"
				_go_to(villager, _pick(paths.tiles_of(TILE_STREET)), move_speed, func() -> void:
					villager.linger("catching breath", _range("breath_min", "breath_max")))
			else:
				villager.activity = "taking a walk"
				_go_to(villager, _pick(paths.tiles_of(TILE_STREET)), move_speed, func() -> void:
					villager.linger("looking around", _range("idle_min", "idle_max")))


## Sends [param villager] to a free ramen seat (story 012): it walks to the seat's approach tile,
## steps up to the seat, faces ramen_seat_facing and lingers "eating ramen". The caller checks
## that a seat is free.
func _go_ramen(villager: Villager, run: bool, move_speed: float) -> void:
	var seat: int = _free_index(_seats.size(), _seat_users)
	_seat_users[seat] = villager
	var point: Vector2 = _seats[seat]
	villager.activity = "running for ramen" if run else "off for a bowl of ramen"
	var eat: Callable = func() -> void:
		_face(villager, _point("ramen_seat_facing"))
		villager.linger("eating ramen", _market_linger("ramen_min", "ramen_max", _is_awake(villager) and _stand_open()))
	_go_to(villager, _approach_tile(point), move_speed, eat, point)


## Sends [param villager] to a free browse spot on the market lane (story 012), facing the
## stalls, "browsing the market". The caller checks that a spot is free.
func _go_browse(villager: Villager, run: bool, move_speed: float) -> void:
	var spots: Array = _browse_spots()
	var k: int = _free_index(spots.size(), _browse_users)
	_browse_users[k] = villager
	var spot: Array = spots[k]
	var stand: Vector2 = Vector2(float(spot[0]), float(spot[1]))
	var look_at: Vector2 = Vector2(float(spot[2]), float(spot[3]))
	villager.activity = "running to the market" if run else "off to the market"
	var browse: Callable = func() -> void:
		_face(villager, look_at - stand)
		villager.linger("browsing the market", _market_linger("browse_min", "browse_max", _is_awake(villager)))
	_go_to(villager, _approach_tile(stand), move_speed, browse, stand)


## A market linger: [param min_key]..[param max_key] s while [param open], else (the villager is due
## home or the ramen stand has closed) only up to dusk_stagger, so nobody lingers at a closed market.
func _market_linger(min_key: String, max_key: String, open: bool) -> float:
	return _range(min_key, max_key) if open else rng.randf() * _t("dusk_stagger")


## When the ramen stand closes (its cook goes off duty): the villagers eating at it finish within
## dusk_stagger s and leave.
func _close_stand() -> void:
	for seat: Variant in _seat_users:
		var eater: Villager = _seat_users[seat]
		if eater.lock == null and eater.state == Villager.State.IDLE:
			eater.timer = minf(eater.timer, rng.randf() * _t("dusk_stagger"))


## The tuning browse_spots ([stand_i, stand_j, look_i, look_j] each).
func _browse_spots() -> Array:
	return _tuning["browse_spots"]


## A random index below [param count] that is not a key of [param users]; -1 when all are taken.
func _free_index(count: int, users: Dictionary) -> int:
	var free: Array[int] = []
	for k: int in count:
		if not users.has(k):
			free.append(k)
	if free.is_empty():
		return -1
	return free[rng.randi_range(0, free.size() - 1)]


## The walk tile that reaches tile point [param point]: its own tile when walkable, else the
## tile in front of it (+j, the door convention), e.g. a ramen seat's tile on the market lane.
func _approach_tile(point: Vector2) -> Vector2i:
	var tile: Vector2i = Vector2i(point.floor())
	if paths.is_walkable(tile):
		return tile
	return tile + Vector2i(0, 1)


## Frees the training post, ramen seat and browse spot [param villager] holds, if any.
func _release_spots(villager: Villager) -> void:
	_release_post(villager)
	for users: Dictionary in [_seat_users, _browse_users]:
		for k: Variant in users.keys():
			if users[k] == villager:
				users.erase(k)


## Rolls an activity for [param villager_type] by its activity_weights (a missing key is 0).
func _roll_activity(villager_type: String) -> String:
	var weights: Dictionary = _tuning["activity_weights"][villager_type]
	var roll: float = rng.randf()
	var total: float = 0.0
	for activity: String in ACTIVITIES:
		total += float(weights.get(activity, 0.0))
		if roll < total:
			return activity
	return ACTIVITY_FALLBACK


## Sends [param villager] to a free training post (story 014): it stands at the post's spot
## facing the post and cycles its training poses. With every post taken it trains on one of
## the train_free_tiles instead.
func _go_train(villager: Villager, run: bool, move_speed: float) -> void:
	villager.activity = "running to training" if run else "off to train"
	var poses: Array[int] = Villager.TRAINING_POSES if villager.has_combat_poses() else Villager.WALK_CYCLE
	var train_here: Callable = func() -> void:
		villager.linger("training", _range("idle_min", "idle_max"), poses, _t("train_pose_seconds"))
	var spots: Array = _tuning["train_post_spots"]
	var free_posts: Array[int] = []
	for k: int in spots.size():
		if not _post_users.has(k):
			free_posts.append(k)
	if free_posts.is_empty():
		_go_to(villager, _pick(_tiles_of_key("train_free_tiles")), move_speed, train_here)
		return
	var post: int = free_posts[rng.randi_range(0, free_posts.size() - 1)]
	_post_users[post] = villager
	var spot: Array = spots[post]
	var stand: Vector2 = Vector2(float(spot[0]), float(spot[1]))
	var look_at: Vector2 = Vector2(float(spot[2]), float(spot[3]))
	var at_post: Callable = func() -> void:
		_face(villager, look_at - stand)
		train_here.call()
	_go_to(villager, Vector2i(stand.floor()), move_speed, at_post, stand)


## A trainer's pause at the memorial stone (story 014): walks to memorial_spot, faces the
## stone, lingers memorial_min..memorial_max s, then goes on to train.
func _visit_memorial(villager: Villager) -> void:
	var spot: Array = _tuning["memorial_spot"]
	var stand: Vector2 = Vector2(float(spot[0]), float(spot[1]))
	var look_at: Vector2 = Vector2(float(spot[2]), float(spot[3]))
	villager.activity = "walking to the memorial stone"
	_next_choice[villager] = ACTIVITY_TRAIN
	var pause: Callable = func() -> void:
		_face(villager, look_at - stand)
		villager.linger("pausing at the memorial stone", _range("memorial_min", "memorial_max"))
	_go_to(villager, Vector2i(stand.floor()), _t("walk_speed"), pause, stand)


## Turns [param villager] toward the tile-space [param direction], by the same rule as
## walking ([method Villager.step]).
func _face(villager: Villager, direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		villager.facing_back = direction.x < 0.0
		villager.flipped = true
	else:
		villager.facing_back = direction.y < 0.0
		villager.flipped = false


## Frees the training post [param villager] holds, if any.
func _release_post(villager: Villager) -> void:
	for post: Variant in _post_users.keys():
		if _post_users[post] == villager:
			_post_users.erase(post)


## The [i, j] tiles listed in tuning key [param key].
func _tiles_of_key(key: String) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var pairs: Array = _tuning[key]
	for pair: Array in pairs:
		tiles.append(Vector2i(int(pair[0]), int(pair[1])))
	return tiles


## Deals a look sheet for body [param body] ("ninja", "kunoichi", "elder", "kid") from that
## body's seeded deck of the tuning [code]looks[/code], skipping any sheet in [param avoid]
## (e.g. the looks of the same house). Every look of a body is dealt once before any repeats.
## Returns [param body] itself when the body has no looks, and a random clashing look only
## when every look of the body is in [param avoid]. Valid once this node has set up.
## Example: [code]var look: String = routines.pick_look("kid", ["kid_look2"])[/code]
func pick_look(body: String, avoid: Array[String] = []) -> String:
	var looks: Array = _looks.get(body, [])
	if looks.is_empty():
		_sheets_in_use[body] = true
		return body
	var deck: Array = _look_decks.get(body, [])
	if deck.all(func(sheet: String) -> bool: return sheet in avoid):
		deck.append_array(_shuffled(looks))
	_look_decks[body] = deck
	var chosen: String = looks[rng.randi_range(0, looks.size() - 1)]
	for k: int in deck.size():
		if not deck[k] in avoid:
			chosen = deck[k]
			deck.remove_at(k)
			break
	_sheets_in_use[chosen] = true
	return chosen


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, LAYOUT_KEYS)
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or _tuning.is_empty():
		get_tree().quit(1)
		return
	rng.seed = int(_tuning["villager_seed"])
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
		elif door["kind"] == DOOR_HOSPITAL:
			_hospital_doors.append(door_tile)
		elif door["kind"] == DOOR_MARKET:
			_market_doors.append(door_tile)
	var seats: Array = layout.get(KEY_RAMEN_SEATS, [])
	for pair: Array in seats:
		_seats.append(Vector2(float(pair[0]), float(pair[1])))
	_check_map(layout)
	_station_list = (_tuning["market_stations"] as Array) + (_tuning["academy_stations"] as Array)
	_load_looks(layout["sprites"])
	_spawn(layout["sprites"], home_doors)
	_check_market(layout)
	_report_looks.call_deferred()
	clock.dawn.connect(_on_dawn)
	clock.dusk.connect(_on_dusk)
	train.arrived.connect(_on_train_arrived)
	train.departing.connect(_on_train_departing)
	set_physics_process(true)
	if ARG_GATE_WALK_NOW in OS.get_cmdline_user_args():
		_gate_walk_now.call_deferred()


## Startup check: logs (push_error) every door tile that cannot be reached from the plaza,
## every tuning tile key that points at a wrong tile, and a cat sparrow row without street.
func _check_map(layout: Dictionary) -> void:
	var plaza_tiles: Array[Vector2i] = paths.tiles_of(TILE_PLAZA)
	if plaza_tiles.is_empty():
		push_error("VillagerRoutines: the map has no '%s' tiles, so doors cannot be checked" % TILE_PLAZA)
		return
	var plaza: Vector2i = plaza_tiles[0]
	var doors: Array = layout["doors"]
	for door: Dictionary in doors:
		var door_tile: Vector2i = Vector2i(int(door["door"][0]), int(door["door"][1]))
		if door_tile != plaza and (not paths.is_walkable(door_tile) or paths.find_path(plaza, door_tile).is_empty()):
			push_error("VillagerRoutines: door %s of the building at (%d, %d) is not reachable from the plaza"
				% [door_tile, int(door["i"]), int(door["j"])])
	var size: int = int(layout["size"])
	var walkable_keys: Array = _tuning["check_walkable_keys"]
	for key: String in walkable_keys:
		_check_tile_key(key, size, true)
	var inside_keys: Array = _tuning["check_inside_keys"]
	for key: String in inside_keys:
		_check_tile_key(key, size, false)
	var row: int = int(_t(KEY_CAT_ROW))
	var has_street: bool = false
	for tile: Vector2i in paths.tiles_of(TILE_STREET):
		if tile.y == row and tile.x >= int(_t(KEY_CAT_MIN_I)) and tile.x <= int(_t(KEY_CAT_MAX_I)):
			has_street = true
	if not has_street:
		push_error("VillagerRoutines: tuning '%s' (%s..%s) has no street tile" % [KEY_CAT_ROW, KEY_CAT_MIN_I, KEY_CAT_MAX_I])


## Checks the tile (or list of tiles) in tuning key [param key]: on the map, and walkable
## when [param must_walk]. Logs the key name when it is off.
func _check_tile_key(key: String, size: int, must_walk: bool) -> void:
	if not _tuning.has(key):
		push_error("VillagerRoutines: tuning has no '%s' (listed for the tile check)" % key)
		return
	var value: Array = _tuning[key]
	var pairs: Array = value if not value.is_empty() and value[0] is Array else [value]
	for pair: Array in pairs:
		var tile: Vector2i = Vector2i(floori(float(pair[0])), floori(float(pair[1])))
		var inside: bool = tile.x >= 0 and tile.y >= 0 and tile.x < size and tile.y < size
		if not inside or (must_walk and not paths.is_walkable(tile)):
			push_error("VillagerRoutines: tuning '%s' tile %s is %s" % [key, tile, "not walkable" if inside else "outside the map"])


## Fills [member _looks] from the tuning [code]looks[/code], keeping only sheets in the sprite
## table [param sprites]; logs (push_error) every look or role sheet that is missing from it.
func _load_looks(sprites: Dictionary) -> void:
	var table: Dictionary = _tuning[KEY_LOOKS]
	for body: String in table:
		var valid: Array = []
		var sheets: Array = table[body]
		for sheet: String in sheets:
			if sprites.has(sheet):
				valid.append(sheet)
			else:
				push_error("VillagerRoutines: look '%s' of '%s' is not in the layout's sprite table" % [sheet, body])
		_looks[body] = valid
	var roles: Dictionary = _tuning[KEY_ROLES]
	for role: String in roles:
		var sheet: String = str(roles[role].get(ROLE_SHEET, ""))
		if not sprites.has(sheet):
			push_error("VillagerRoutines: role '%s' sheet '%s' is not in the layout's sprite table" % [role, sheet])


## A copy of [param items] in a random order from the seeded generator (never the global one).
func _shuffled(items: Array) -> Array:
	var out: Array = items.duplicate()
	for k: int in range(out.size() - 1, 0, -1):
		var swap: int = rng.randi_range(0, k)
		var held: Variant = out[k]
		out[k] = out[swap]
		out[swap] = held
	return out


## Prints once, after every spawner has set up, how many distinct sheets are worn.
func _report_looks() -> void:
	print("VillagerRoutines: %d distinct looks in use (%d residents)" % [_sheets_in_use.size(), villagers.size()])


## The looks already worn by residents whose home door is [param door].
func _house_looks(door: Vector2i) -> Array[String]:
	var worn: Array[String] = []
	for other: Villager in villagers:
		if other.home_door == door:
			worn.append(other.look)
	return worn


## Makes resident number [param k] (its name and home door are entry k of the lists, repeated)
## of body [param villager_type] wearing [param sheet] (a look is picked when it is empty or
## missing from the sprite table), hidden at its door, and adds it to [member villagers].
func _spawn_one(k: int, sprites: Dictionary, home_doors: Array[Vector2i], villager_type: String,
		sheet: String = "") -> Villager:
	var names: Array = _tuning["villager_names"]
	var villager: Villager = VILLAGER_SCENE.instantiate() as Villager
	var door: Vector2i = home_doors[k % home_doors.size()]
	var offset: Vector2 = Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * _t("path_jitter")
	var look: String = sheet if sprites.has(sheet) else pick_look(villager_type, _house_looks(door))
	_sheets_in_use[look] = true
	villager.setup(village, sprites.get(look, sprites[villager_type]), names[k % names.size()], villager_type,
		door, offset, _t("walk_frames_per_tile"), look)
	villager.visible = false
	villager.place(Vector2(villager.home_door) + Vector2(0.5, _t("door_inset")))
	village.add_entity(villager)
	villagers.append(villager)
	return villager


func _spawn(sprites: Dictionary, home_doors: Array[Vector2i]) -> void:
	var types: Array = _tuning["villager_types"]
	var ninjas: Array[Villager] = []
	var index: int = 0
	for resident: int in int(_tuning["residents"]):
		var villager_type: String = types[index % types.size()]
		var villager: Villager = _spawn_one(index, sprites, home_doors, villager_type)
		index += 1
		if villager_type == TYPE_NINJA:
			ninjas.append(villager)
	var roles: Dictionary = _tuning[KEY_ROLES]
	for role: String in roles:
		var info: Dictionary = roles[role]
		for n: int in int(info[ROLE_COUNT]):
			var villager: Villager = _spawn_one(index, sprites, home_doors, str(info[ROLE_BASE_TYPE]), str(info[ROLE_SHEET]))
			villager.role = role
			villager.role_title = str(info[ROLE_TITLE])
			index += 1
	for k: int in mini(int(_tuning["night_watch"]), ninjas.size()):
		var watcher: Villager = ninjas.pop_at(rng.randi_range(0, ninjas.size() - 1))
		watcher.night_watch = true
	# Guards first, so a guard due on duty counts as awake below (story 011).
	_setup_guards()
	_setup_stations()
	# A lively start: most villagers who are awake are already out.
	for villager: Villager in villagers:
		if _is_awake(villager) and rng.randf() < _t("start_outside_chance"):
			villager.visible = true
			villager.place(Vector2(_pick(paths.walkable_tiles)) + Vector2(0.5, 0.5) + villager.offset_in_tile)
			villager.linger("looking around", _range("start_idle_min", "start_idle_max"))
		else:
			villager.timer = rng.randf() * _t("leave_stagger")


func _is_awake(villager: Villager) -> bool:
	if _guard_due(villager) != Shift.NONE:
		return true
	var t: float = clock.time
	if villager.night_watch:
		return t >= clock.home_time - _t("watch_out_before") or t < clock.wake_time + _t("watch_home_after")
	return t >= clock.wake_time and t < clock.home_time


func _leave_home(villager: Villager) -> void:
	_resting.erase(villager)
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
		villager.timer = rng.randf() * _t("leave_stagger")
	_go_to(villager, villager.home_door, _t("walk_speed"), go_indoors, into_door)


## Walks [param villager] at [param move_speed] tiles per second by the shortest path to
## [param tile] (its own offset from the tile centre), then optionally on to [param extra],
## then calls [param on_arrive].
func _go_to(villager: Villager, tile: Vector2i, move_speed: float, on_arrive: Callable, extra: Variant = null) -> void:
	var from: Vector2i = _approach_tile(villager.tile_pos)
	if not paths.is_walkable(from):
		from = villager.home_door
	var points: Array[Vector2] = []
	for step: Vector2i in paths.find_path(from, tile):
		points.append(Vector2(step) + Vector2(0.5, 0.5) + villager.offset_in_tile)
	if points.is_empty() and extra == null:
		# Already on the target tile (e.g. leaving a ramen seat for the lane tile): still step onto it.
		points.append(Vector2(tile) + Vector2(0.5, 0.5) + villager.offset_in_tile)
	if extra != null:
		points.append(extra)
	villager.follow(points, move_speed, on_arrive)


func _on_dawn() -> void:
	for villager: Villager in villagers:
		if villager.state == Villager.State.HOME and not _resting.has(villager):
			villager.timer = rng.randf() * _t("leave_stagger")


func _on_dusk() -> void:
	for villager: Villager in villagers:
		if villager.lock == null and villager.state in [Villager.State.IDLE, Villager.State.WAIT] \
				and not _is_awake(villager):
			villager.timer = minf(villager.timer, rng.randf() * _t("dusk_stagger"))


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
	return tiles[rng.randi_range(0, tiles.size() - 1)]


func _range(min_key: String, max_key: String) -> float:
	return rng.randf_range(_t(min_key), maxf(_t(min_key), _t(max_key)))


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


## Picks the gate guards (story 011): the guard_role villagers, one per guard_posts entry,
## and logs (push_error) a role count the posts cannot hold or a missing role.
func _setup_guards() -> void:
	var posts: Array = _tuning["guard_posts"]
	var role: String = str(_tuning["guard_role"])
	var found: int = 0
	for villager: Villager in villagers:
		if villager.role != role:
			continue
		found += 1
		if _guards.size() < posts.size():
			_guards.append(villager)
	if found == 0:
		push_error("VillagerRoutines: tuning 'guard_role' '%s' has no villagers (see 'roles')" % role)
	elif found > posts.size():
		push_error("VillagerRoutines: %d '%s' villagers but only %d guard_posts" % [found, role, posts.size()])
	_was_evening = clock.time >= clock.home_time


## Guard duty check (every guard_check_seconds): rotates the night watch once per evening,
## puts free guards whose shift is on to work, takes guards off at the end of their shift,
## and sends a night guard home to rest when the day shift starts.
func _update_guards() -> void:
	if _guards.is_empty():
		return
	var evening: bool = clock.time >= clock.home_time
	if evening and not _was_evening and bool(_tuning["guard_swap_daily"]):
		_night_start = (_night_start + _night_count()) % _guards.size()
	_was_evening = evening
	for k: int in _guards.size():
		var guard: Villager = _guards[k]
		var want: int = _shift_of(k)
		var on: int = int(_guard_shift.get(guard, Shift.NONE))
		if on == Shift.NONE:
			if want != Shift.NONE and not _resting.has(guard) and guard.lock == null and guard.visible \
					and guard.state in [Villager.State.IDLE, Villager.State.WALK, Villager.State.WAIT]:
				_start_duty(guard, want)
		elif guard.lock != self:
			_guard_shift.erase(guard)
		elif want == Shift.NONE:
			_end_duty(guard)
		elif want != on:
			if on == Shift.NIGHT:
				_rest(guard)
			else:
				_guard_shift[guard] = want
				if guard.state == Villager.State.IDLE:
					guard.activity = _duty_label(want)


## How many guards keep the night watch (guard_night_watch, at most every guard).
func _night_count() -> int:
	return mini(int(_t("guard_night_watch")), _guards.size())


## The shift guard [param k] should be on now ([enum Shift]): the day shift from its start
## after wake_time to home_time; the night watch, for this night's night guards, otherwise.
func _shift_of(k: int) -> int:
	var t: float = clock.time
	var start: float = clock.wake_time + _t("guard_on_after_wake") + k * _t("guard_shift_stagger")
	if t >= start and t < clock.home_time:
		return Shift.DAY
	if posmod(k - _night_start, _guards.size()) < _night_count() and (t >= clock.home_time or t < start):
		return Shift.NIGHT
	return Shift.NONE


## The shift [param villager] should be on now ([enum Shift]): NONE for anyone but a guard,
## and for a guard resting after the night watch.
func _guard_due(villager: Villager) -> int:
	var k: int = _guards.find(villager)
	if k < 0 or _resting.has(villager):
		return Shift.NONE
	return _shift_of(k)


## Starts [param villager]'s shift if it is a guard that is due on duty; true when it did.
func _start_duty_if_due(villager: Villager) -> bool:
	var shift: int = _guard_due(villager)
	if shift == Shift.NONE:
		return false
	_start_duty(villager, shift)
	return true


## Holds [param guard] (lock = this node) and walks it to its post, where it stands facing
## along the post's look point (down the street) with its duty label.
func _start_duty(guard: Villager, shift: int) -> void:
	var spot: Array = _tuning["guard_posts"][_guards.find(guard)]
	var stand: Vector2 = Vector2(float(spot[0]), float(spot[1]))
	var look_at: Vector2 = Vector2(float(spot[2]), float(spot[3]))
	_release_spots(guard)
	_next_choice.erase(guard)
	guard.lock = self
	_guard_shift[guard] = shift
	guard.activity = "heading to the gate"
	var at_post: Callable = func() -> void:
		_face(guard, look_at - stand)
		guard.linger(_duty_label(int(_guard_shift.get(guard, shift))), _t("guard_check_seconds"))
	_go_to(guard, Vector2i(stand.floor()), _t("walk_speed"), at_post, stand)


## Takes [param guard] off duty and back to its routine (home, when it is not its time out).
func _end_duty(guard: Villager) -> void:
	_guard_shift.erase(guard)
	guard.lock = null
	next_activity(guard)


## Sends a night guard home to rest guard_rest s after the watch, held until it is indoors;
## it comes back on duty when it next leaves home ([method _leave_home]).
func _rest(guard: Villager) -> void:
	_guard_shift.erase(guard)
	_resting[guard] = true
	guard.activity = "going home to rest"
	var into_door: Vector2 = Vector2(guard.home_door) + Vector2(0.5, _t("door_inset"))
	var indoors: Callable = func() -> void:
		guard.lock = null
		guard.disappear(Villager.State.HOME, "resting after the night watch")
		guard.timer = _t("guard_rest")
	_go_to(guard, guard.home_door, _t("walk_speed"), indoors, into_door)


## The activity text of a guard at its post on [param shift].
func _duty_label(shift: int) -> String:
	return "keeping the night watch at the gate" if shift == Shift.NIGHT else "guarding the gate"


## At the gate: holds [param villager] (so no event picks it outside the wall), walks it
## straight out to [param outside] (off the path grid) and lets it linger there.
func _step_out(villager: Villager, outside: Vector2) -> void:
	villager.lock = self
	villager.activity = "stepping out of the village"
	_outside[villager] = _range("gate_outside_min", "gate_outside_max")
	var points: Array[Vector2] = [outside]
	villager.follow(points, _t("walk_speed"), func() -> void:
		villager.linger("stepping out of the village", _t("gate_outside_max")))


## Counts down the villagers standing outside the gate; when one's time is up it walks back
## through the passage onto the gate tile, is released and carries on with its routine.
func _tick_outside(delta: float) -> void:
	for villager: Villager in _outside.keys():
		if villager.state != Villager.State.IDLE:
			continue
		_outside[villager] = float(_outside[villager]) - delta
		if float(_outside[villager]) > 0.0:
			continue
		_outside.erase(villager)
		villager.activity = "coming back into the village"
		var back: Array[Vector2] = [_point("gate_centre"),
			Vector2(_tile_of_key("gate_tile")) + Vector2(0.5, 0.5) + villager.offset_in_tile]
		villager.follow(back, _t("walk_speed"), func() -> void:
			villager.lock = null
			next_activity(villager))


## [code]--gate-walk-now[/code]: sends the free villager nearest the gate (not a guard or a
## night watcher) out through it at once.
func _gate_walk_now() -> void:
	var walker: Villager = find_nearest(_point("gate_centre"), func(v: Villager) -> bool:
		return v.lock == null and not v.night_watch and not _guards.has(v) \
			and not _keepers.has(v) and v.state in [Villager.State.IDLE, Villager.State.WALK])
	if walker == null or not _is_awake(walker):
		push_warning("VillagerRoutines: %s found no free villager to send out" % ARG_GATE_WALK_NOW)
		return
	_next_choice[walker] = ACTIVITY_GATE
	next_activity(walker)


## The tile point [i, j] in tuning key [param key].
func _point(key: String) -> Vector2:
	var pair: Array = _tuning[key]
	return Vector2(float(pair[0]), float(pair[1]))


## The tile holding the tile point in tuning key [param key].
func _tile_of_key(key: String) -> Vector2i:
	return Vector2i(_point(key).floor())


## Gives each market station (story 012) a villager: the k-th villager of a role takes the k-th
## station of that role. Logs (push_error) a station with no villager and role villagers left over.
func _setup_stations() -> void:
	var stations: Array = _station_list
	var taken: Dictionary = {}
	var roles: Dictionary = {}
	for k: int in stations.size():
		roles[str(stations[k][STATION_ROLE])] = true
	for villager: Villager in villagers:
		if not roles.has(villager.role):
			continue
		for k: int in stations.size():
			if not taken.has(k) and str(stations[k][STATION_ROLE]) == villager.role:
				taken[k] = true
				_keepers[villager] = k
				break
		if not _keepers.has(villager):
			push_error("VillagerRoutines: %s (%s) has no station (see 'market_stations', 'academy_stations')" % [villager.villager_name, villager.role])
	for k: int in stations.size():
		if not taken.has(k):
			push_error("VillagerRoutines: station %d ('%s') has no '%s' villager (see 'roles')"
				% [k, stations[k][STATION_LABEL], stations[k][STATION_ROLE]])


## Startup check of the market (story 012): every ramen seat, browse spot and station point must
## be reachable from the plaza over its approach tile; logs (push_error) each one that is not.
func _check_market(layout: Dictionary) -> void:
	if _seats.is_empty():
		push_error("VillagerRoutines: the layout has no '%s', so nobody can eat ramen" % KEY_RAMEN_SEATS)
	if _market_doors.is_empty():
		push_error("VillagerRoutines: the layout has no '%s' doors; shoppers use the old shops" % DOOR_MARKET)
	var plaza_tiles: Array[Vector2i] = paths.tiles_of(TILE_PLAZA)
	if plaza_tiles.is_empty():
		return
	var points: Dictionary = {}
	for k: int in _seats.size():
		points["%s %d" % [KEY_RAMEN_SEATS, k]] = _seats[k]
	var spots: Array = _browse_spots()
	for k: int in spots.size():
		points["browse_spots %d" % k] = Vector2(float(spots[k][0]), float(spots[k][1]))
	var stations: Array = _station_list
	for k: int in stations.size():
		var stand: Array = stations[k][STATION_STAND]
		points["station %d ('%s')" % [k, stations[k][STATION_LABEL]]] = Vector2(float(stand[0]), float(stand[1]))
	var size: int = int(layout["size"])
	for label: String in points:
		var point: Vector2 = points[label]
		var tile: Vector2i = _approach_tile(point)
		var inside: bool = tile.x >= 0 and tile.y >= 0 and tile.x < size and tile.y < size
		if not inside or not paths.is_walkable(tile) or paths.find_path(plaza_tiles[0], tile).is_empty():
			push_error("VillagerRoutines: %s %s cannot be reached (approach tile %s)" % [label, point, tile])


## True while a ramen_role villager is on duty at (or on the way to) its station: the stand is open.
func _stand_open() -> bool:
	var role: String = str(_tuning["ramen_role"])
	for villager: Villager in _station_on:
		if villager.role == role:
			return true
	return false


## True when [param villager] has a market station and it is that station's working time.
func _station_due(villager: Villager) -> bool:
	if not _keepers.has(villager):
		return false
	var start: float = clock.wake_time + _t("station_on_after_wake") + int(_keepers[villager]) * _t("station_shift_stagger")
	return clock.time >= start and clock.time < clock.home_time


## Starts [param villager]'s market shift if it is due and not on it yet; true when it did.
func _start_station_if_due(villager: Villager) -> bool:
	if _station_on.has(villager) or not _station_due(villager):
		return false
	_start_station(villager)
	return true


## Market station check (with the guard check): puts free villagers whose shift is on to work,
## forgets ones taken over by something else, and takes them off at home time (they go home).
func _update_stations() -> void:
	for villager: Villager in _keepers:
		var due: bool = _station_due(villager)
		if not _station_on.has(villager):
			if due and villager.lock == null and villager.visible \
					and villager.state in [Villager.State.IDLE, Villager.State.WALK, Villager.State.WAIT]:
				_start_station(villager)
		elif villager.lock != self:
			_station_on.erase(villager)
		elif not due:
			_station_on.erase(villager)
			villager.lock = null
			if villager.role == str(_tuning["ramen_role"]):
				_close_stand()
			next_activity(villager)


## Holds [param villager] (lock = this node) and walks it to its station's stand point, where it
## faces the look point with the station's label.
func _start_station(villager: Villager) -> void:
	var station: Dictionary = _station_list[int(_keepers[villager])]
	var stand_pair: Array = station[STATION_STAND]
	var look_pair: Array = station[STATION_LOOK]
	var stand: Vector2 = Vector2(float(stand_pair[0]), float(stand_pair[1]))
	var look_at: Vector2 = Vector2(float(look_pair[0]), float(look_pair[1]))
	_release_spots(villager)
	_next_choice.erase(villager)
	villager.lock = self
	_station_on[villager] = true
	villager.activity = str(station[STATION_HEADING])
	var at_station: Callable = func() -> void:
		_face(villager, look_at - stand)
		villager.linger(str(station[STATION_LABEL]), _t("guard_check_seconds"))
	_go_to(villager, _approach_tile(stand), _t("walk_speed"), at_station, stand)
