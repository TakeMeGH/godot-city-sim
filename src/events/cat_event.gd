class_name CatEvent
extends VillageEvent
## Cat and sparrow (story 005): a sparrow lands on a street tile of row
## [code]cat_bird_row[/code] (i from [code]cat_bird_min_i[/code] to [code]cat_bird_max_i[/code]),
## a cat stalks it
## from [code]cat_home[/code] along the streets, the sparrow escapes over the roofs when
## the cat gets within [code]cat_pounce_range[/code] tiles, the cat sits a while, then
## wanders home to a random house door and goes in. Holds no villagers.
##
## Cat phases: STALK -> SIT (path done; after [code]cat_sit_seconds[/code] with the
## sparrow gone) -> HOME -> end. The sparrow is on the ground until the pounce, then
## flies. Ends anyway after [code]cat_timeout[/code] s. At dusk the sparrow flies off
## and the cat heads home at once.
##
## Tuning keys (tiles, tiles per second, pixels per second, seconds): cat_home,
## cat_bird_row, cat_bird_min_i, cat_bird_max_i, cat_speed, cat_pounce_range, cat_sit_seconds,
## cat_timeout, cat_walk_frames_per_tile, bird_hop_rate, bird_flap_rate,
## bird_fly_velocity, (shared) door_inset.

enum Phase { STALK, SIT, HOME }

const TRANSITIONS: Dictionary = {
	Phase.STALK: [Phase.SIT, Phase.HOME],
	Phase.SIT: [Phase.HOME],
}
const CAT_SPRITE: String = "cat"
const BIRD_SPRITE: String = "bird"

var _phase: Phase = Phase.STALK
var _time: float = 0.0
var _cat: Sprite2D = null
var _cat_pos: Vector2 = Vector2.ZERO
var _cat_path: Array[Vector2] = []
var _cat_distance: float = 0.0
var _cat_flipped: bool = false
var _bird: Sprite2D = null
var _bird_tile_pos: Vector2 = Vector2.ZERO
var _bird_world: Vector2 = Vector2.ZERO
var _bird_flying: bool = false


## Puts the sparrow on the main street and the cat at its start, on a street path to it.
func start() -> bool:
	var d: EventDirector = _director
	var paths: VillagePaths = d.routines.paths
	var row: int = int(d.t("cat_bird_row"))
	var min_i: int = int(d.t("cat_bird_min_i"))
	var max_i: int = int(d.t("cat_bird_max_i"))
	var choices: Array[Vector2i] = []
	for tile: Vector2i in paths.tiles_of(VillagerRoutines.TILE_STREET):
		if tile.y == row and tile.x >= min_i and tile.x <= max_i:
			choices.append(tile)
	if choices.is_empty():
		choices = paths.tiles_of(VillagerRoutines.TILE_STREET)
	if choices.is_empty():
		return false
	var bird_tile: Vector2i = choices[d.rng().randi_range(0, choices.size() - 1)]
	var home: Vector2i = d.tile("cat_home")
	_bird_tile_pos = Vector2(bird_tile) + Vector2(0.5, 0.5)
	_cat_pos = Vector2(home) + Vector2(0.5, 0.5)
	_cat_path = _centres(paths.find_path(home, bird_tile))
	_cat_flipped = true
	_cat = d.add_critter(CAT_SPRITE, false)
	_bird = d.add_critter(BIRD_SPRITE, false)
	d.log_line("A sparrow lands on the main street. A cat has seen it")
	_draw()
	return true


## Steps the stalk, the pounce, the sparrow's flight and the walk home.
func update(delta: float) -> void:
	if done:
		return
	var d: EventDirector = _director
	phase_time += delta
	_time += delta
	_walk(delta)
	if not _bird_flying and _cat_pos.distance_to(_bird_tile_pos) < d.t("cat_pounce_range"):
		_fly_off()
		d.log_line("The cat pounces. The sparrow escapes over the roofs")
	if _bird_flying:
		_bird_world += d.point("bird_fly_velocity") * delta
	match _phase:
		Phase.STALK:
			if _cat_path.is_empty():
				_go(Phase.SIT)
		Phase.SIT:
			if _bird_flying and phase_time > d.t("cat_sit_seconds"):
				_head_home()
		Phase.HOME:
			if _cat_path.is_empty():
				finish()
				return
	if _time > d.t("cat_timeout"):
		finish()
		return
	_draw()


func _wind_down() -> void:
	if not _bird_flying:
		_fly_off()
	if _phase != Phase.HOME:
		_head_home()


func _cleanup() -> void:
	for sprite: Variant in [_cat, _bird]:
		if is_instance_valid(sprite):
			(sprite as Node).queue_free()
	_cat = null
	_bird = null


func _go(to: Phase) -> void:
	_check_transition(TRANSITIONS, _phase, to)
	_phase = to


func _fly_off() -> void:
	_bird_flying = true
	_bird_world = _director.village.tile_to_world(_bird_tile_pos.x, _bird_tile_pos.y)
	_bird.z_index = EventDirector.SKY_Z_INDEX


func _head_home() -> void:
	_go(Phase.HOME)
	var d: EventDirector = _director
	var doors: Array[Vector2i] = d.home_doors
	var from: Vector2i = Vector2i(_cat_pos.floor())
	if not d.routines.paths.is_walkable(from):
		from = d.tile("cat_home")
	if doors.is_empty():
		_cat_path.clear()
		return
	var door: Vector2i = doors[d.rng().randi_range(0, doors.size() - 1)]
	_cat_path = _centres(d.routines.paths.find_path(from, door))
	_cat_path.append(Vector2(door) + Vector2(0.5, d.t("door_inset")))
	d.log_line("The cat gives up and wanders home")


func _walk(delta: float) -> void:
	var budget: float = _director.t("cat_speed") * delta
	while budget > 0.0 and not _cat_path.is_empty():
		var to: Vector2 = _cat_path[0] - _cat_pos
		var distance: float = to.length()
		if absf(to.x) > absf(to.y):
			_cat_flipped = to.x > 0.0
		else:
			_cat_flipped = to.y < 0.0
		if distance <= budget:
			_cat_pos = _cat_path[0]
			_cat_path.remove_at(0)
			budget -= distance
			_cat_distance += distance
		else:
			_cat_pos += to / distance * budget
			_cat_distance += budget
			budget = 0.0


func _draw() -> void:
	var d: EventDirector = _director
	_cat.position = d.village.tile_to_world(_cat_pos.x, _cat_pos.y)
	_cat.frame = 0
	if not _cat_path.is_empty():
		_cat.frame = floori(_cat_distance * d.t("cat_walk_frames_per_tile")) % _cat.hframes
	d.face(_cat, CAT_SPRITE, _cat_flipped)
	if _bird_flying:
		_bird.frame = floori(_time * d.t("bird_flap_rate")) % _bird.hframes
		_bird.position = _bird_world
	else:
		_bird.frame = floori(_time * d.t("bird_hop_rate")) % _bird.hframes
		# The hop frame also lifts the sparrow one pixel off the street.
		_bird.position = d.village.tile_to_world(_bird_tile_pos.x, _bird_tile_pos.y) - Vector2(0.0, _bird.frame)


func _centres(tiles: Array[Vector2i]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for tile: Vector2i in tiles:
		points.append(Vector2(tile) + Vector2(0.5, 0.5))
	return points
