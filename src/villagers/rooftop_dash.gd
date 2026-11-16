class_name RooftopDash
extends Node
## A ninja dashing across the rooftops (design/game-brief.md, Features item 4; story 004).
## Every [code]rooftop_gap[/code] s on average (each gap randomised by
## [code]rooftop_gap_min_mult[/code]..[code]rooftop_gap_max_mult[/code]; the first after
## [code]rooftop_first[/code] s) a ninja runs along one of the back rows
## ([code]rooftop_rows[/code]) from [code]rooftop_start_i[/code] to past the far edge,
## hopping from roof to roof, with fading afterimages behind it, then is gone.
##
## Roof height per tile comes from the building or tree placed on it
## ([code]roof_heights[/code], pixels per sprite name); a tile with none takes the higher of
## its two neighbours. Between tile centres the height blends from one roof to the next
## plus a [code]rooftop_hop[/code] px arc.
##
## The runner is drawn through [method VillageScene.add_entity]; its sort point is
## [code]rooftop_sort_ahead[/code] tiles in front of the line it runs on, so it shows in
## front of its own row's roofs and behind the next row's.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (seconds, tiles, pixels):
## [codeblock]
## rooftop_first                              first dash after this long
## rooftop_gap, rooftop_gap_min_mult, rooftop_gap_max_mult
##                                            average gap between dashes; random factor range
## rooftop_speed                              tiles per second along the row
## rooftop_rows                               rows (j) the dash may run along
## rooftop_start_i, rooftop_end_margin        starts at this i; ends at village size + margin
## rooftop_hop                                height of the arc between roofs
## rooftop_sprite, rooftop_frames, rooftop_frame_rate
##                                            sprite sheet; run frames; frame swaps per second
## rooftop_afterimages                        [{seconds, alpha}] drawn back to front: an image
##                                            where the runner was that many seconds ago
## rooftop_sort_ahead                         sort point, tiles in front of the run line
## roof_heights                               roof height per placed sprite name
## [/codeblock]
##
## Command-line user arg (after [code]--[/code]) for repeatable screenshots:
## [codeblock]
## godot --path . -- --dash-now   # start a dash at once instead of after rooftop_first
## [/codeblock]

## Emitted when a dash starts. For the village log (stories 005/007).
signal dashed()

const ARG_DASH_NOW: String = "--dash-now"
const TUNING_KEYS: Array[String] = [
	"rooftop_first", "rooftop_gap", "rooftop_gap_min_mult", "rooftop_gap_max_mult", "rooftop_speed",
	"rooftop_rows", "rooftop_start_i", "rooftop_end_margin", "rooftop_hop", "rooftop_sprite",
	"rooftop_frames", "rooftop_frame_rate", "rooftop_afterimages", "rooftop_sort_ahead", "roof_heights",
]
const LAYOUT_KEYS: Array[String] = ["size", "placements", "sprites"]

## The village whose roofs are run over.
@export var village: VillageScene
## The villagers' routines, for the seeded generator.
@export var routines: VillagerRoutines

## True while a dash is under way.
var dashing: bool = false

var _tuning: Dictionary = {}
var _roof_at: Dictionary = {}
var _end_i: float = 0.0
var _timer: float = 0.0
var _row: int = 0
var _i: float = 0.0
var _run_time: float = 0.0
var _runner: Node2D = Node2D.new()
## One sprite per afterimage, then the runner itself (drawn last, on top).
var _sprites: Array[Sprite2D] = []
var _lags: Array[float] = []


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	if not dashing:
		_timer -= delta
		if _timer <= 0.0:
			_start()
		return
	_i += _t("rooftop_speed") * delta
	_run_time += delta
	if _i > _end_i:
		dashing = false
		_runner.visible = false
		_timer = _t("rooftop_gap") * routines.rng.randf_range(_t("rooftop_gap_min_mult"), _t("rooftop_gap_max_mult"))
		return
	_place_runner()


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, LAYOUT_KEYS)
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or _tuning.is_empty():
		get_tree().quit(1)
		return
	var size: float = float(layout["size"])
	_end_i = size + _t("rooftop_end_margin")
	var heights: Dictionary = _tuning["roof_heights"]
	var placements: Array = layout["placements"]
	for entry: Dictionary in placements:
		var i: float = float(entry["i"])
		var j: float = float(entry["j"])
		if heights.has(entry["sprite"]) and i >= 0.0 and j >= 0.0 and i <= size and j <= size:
			_roof_at[Vector2i(floori(i), floori(j))] = float(heights[entry["sprite"]])
	var sprite_name: String = _tuning["rooftop_sprite"]
	var info: Dictionary = layout["sprites"][sprite_name]
	var afterimages: Array = _tuning["rooftop_afterimages"]
	for image: Dictionary in afterimages:
		_add_sprite(sprite_name, info, float(image["alpha"]))
		_lags.append(float(image["seconds"]))
	_add_sprite(sprite_name, info, 1.0)
	_lags.append(0.0)
	_runner.name = "RooftopRunner"
	_runner.visible = false
	village.add_entity(_runner)
	_timer = _t("rooftop_first")
	if ARG_DASH_NOW in OS.get_cmdline_user_args():
		_timer = 0.0
	set_physics_process(true)


func _add_sprite(sprite_name: String, info: Dictionary, alpha: float) -> void:
	var sprite: Sprite2D = village.create_sprite(sprite_name)
	# Running +i faces down-right: the front frames mirrored, offset kept under the anchor.
	sprite.flip_h = true
	sprite.offset.x = -(float(info["w"]) - float(info["ax"]))
	sprite.modulate.a = alpha
	_runner.add_child(sprite)
	_sprites.append(sprite)


func _start() -> void:
	var rows: Array = _tuning["rooftop_rows"]
	_row = int(rows[routines.rng.randi_range(0, rows.size() - 1)])
	_i = _t("rooftop_start_i")
	_run_time = 0.0
	dashing = true
	_runner.visible = true
	_place_runner()
	dashed.emit()


func _place_runner() -> void:
	var line: Vector2 = village.tile_to_world(_i, _row + 0.5)
	var sort_drop: float = (village.tile_to_world(0.0, _t("rooftop_sort_ahead")) - village.tile_to_world(0.0, 0.0)).y
	_runner.position = Vector2(line.x, line.y + sort_drop)
	var frames: Array = _tuning["rooftop_frames"]
	var frame: int = int(frames[floori(_run_time * _t("rooftop_frame_rate")) % frames.size()])
	for k: int in _sprites.size():
		_sprites[k].frame = frame
		_sprites[k].position = _roof_point(_i - _t("rooftop_speed") * _lags[k]) - _runner.position


## World position of the runner's feet at run position [param i] along the current row.
func _roof_point(i: float) -> Vector2:
	var k: int = floori(i - 0.5)
	var f: float = i - 0.5 - k
	var height: float = lerpf(_roof_height(k), _roof_height(k + 1), f) + _t("rooftop_hop") * sin(PI * f)
	return village.tile_to_world(i, _row + 0.5) - Vector2(0.0, height)


func _roof_height(i: int) -> float:
	var tile: Vector2i = Vector2i(i, _row)
	if _roof_at.has(tile):
		return _roof_at[tile]
	return maxf(_roof_at.get(tile + Vector2i.LEFT, 0.0), _roof_at.get(tile + Vector2i.RIGHT, 0.0))


func _t(key: String) -> float:
	return float(_tuning[key])


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("RooftopDash: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("RooftopDash: %s has no '%s'" % [path, key])
			return {}
	return data
