class_name VillageScene
extends Node2D
## The isometric village: ground tiles, buildings, trees, lanterns and street props,
## built from [code]assets/data/village_layout.json[/code]. Camera numbers live in
## [code]assets/data/village_tuning.json[/code].
##
## Every sprite's node origin is its ground anchor, so a node placed at
## [method tile_to_world] stands on that tile point. Everything that must sort against
## the buildings (villagers, train cars, props) lives in the y-sorted [code]World[/code]
## node: add it with [method add_entity] and it is drawn in front of or behind the
## buildings by its y position.
##
## Example (a villager standing in the middle of tile 4,3):
## [codeblock]
## var villager: Sprite2D = village.create_sprite("ninja", 0)
## villager.position = village.tile_to_world(4.5, 3.5)
## village.add_entity(villager)
## [/codeblock]

const LAYOUT_PATH: String = "res://assets/data/village_layout.json"
const TUNING_PATH: String = "res://assets/data/village_tuning.json"
const ART_DIR: String = "res://assets/art/"

const LANTERN_SPRITE: String = "lantern"
const TILES_SPRITE: String = "tiles"
const TILE_TRACK: String = "track"
const TILE_FOREST: String = "forest"
const TILE_GRASS: String = "grass"
const TILE_GRASS_FLOWERS: String = "grass_flowers"

const LAYOUT_KEYS: Array[String] = [
	"size", "tile_width", "tile_height", "ground_margin", "track_row", "flower_rule",
	"building_sprites", "tile_names", "tile_legend", "map", "placements", "doors", "sprites",
]
const TUNING_KEYS: Array[String] = [
	"pan_speed", "drift_after", "drift_x", "drift_y", "cam_range_x", "cam_range_y",
	"cam_range_up_extra", "start_offset_y", "drift_centre_offset_y", "drift_rate_x",
	"drift_rate_y", "drift_phase_y", "drift_ease",
]


## A street lantern: frame 0 is unlit, frame 1 is lit. The glow around a lit lantern
## is not drawn here (night look, story 006).
class Lantern extends Sprite2D:
	const UNLIT_FRAME: int = 0
	const LIT_FRAME: int = 1

	## True while the lit frame is showing.
	var is_lit: bool = false

	## Switches between the unlit and the lit frame.
	## Example: [code]for lantern in village.lanterns: lantern.set_lit(true)[/code]
	func set_lit(lit: bool) -> void:
		is_lit = lit
		frame = LIT_FRAME if lit else UNLIT_FRAME


## Every lantern in the village.
var lanterns: Array[Lantern] = []
## Every house, tower, shop and station sprite. Frame 0 is day, frame 1 is night.
var buildings: Array[Sprite2D] = []
## The village camera.
@onready var camera: CameraRig = $CameraRig

var _layout: Dictionary = {}
var _sprites: Dictionary = {}
var _half_tile: Vector2 = Vector2.ZERO
var _textures: Dictionary = {}

@onready var _ground: Node2D = $Ground
@onready var _world: Node2D = $World


func _ready() -> void:
	_layout = _load_json(LAYOUT_PATH, LAYOUT_KEYS)
	var tuning: Dictionary = _load_json(TUNING_PATH, TUNING_KEYS)
	if _layout.is_empty() or tuning.is_empty():
		get_tree().quit(1)
		return
	_sprites = _layout["sprites"]
	_half_tile = Vector2(float(_layout["tile_width"]), float(_layout["tile_height"])) * 0.5
	_ground.draw.connect(_draw_ground)
	_ground.queue_redraw()
	_place_sprites()
	var centre_tile: float = float(_layout["size"]) * 0.5
	camera.setup(tuning, tile_to_world(centre_tile, centre_tile))


## World position (pixels) of the tile point (i, j). Tile (0,0)'s top corner is the
## origin; i grows down-right, j grows down-left; a tile's centre is (i + 0.5, j + 0.5).
## Valid once the scene is ready.
## Example: [code]village.tile_to_world(6.0, 6.0)[/code] is the village centre.
func tile_to_world(i: float, j: float) -> Vector2:
	return Vector2((i - j) * _half_tile.x, (i + j) * _half_tile.y)


## Adds a node to the y-sorted world so it is depth-sorted against the buildings.
## The node's position is where its ground anchor stands; set it before or after.
func add_entity(node: Node2D) -> void:
	_world.add_child(node)


## Builds a sprite from the layout's sprite table: frame sheet, frame count, and the
## origin on the ground anchor. Not yet added to the scene; pass it to [method add_entity].
## Example: [code]var cat: Sprite2D = village.create_sprite("cat", 1)[/code]
func create_sprite(sprite_name: String, frame: int = 0) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	_apply_sprite(sprite, sprite_name, frame)
	return sprite


func _apply_sprite(sprite: Sprite2D, sprite_name: String, frame: int) -> void:
	var info: Dictionary = _sprites[sprite_name]
	sprite.texture = _texture(sprite_name)
	sprite.hframes = int(info["frames"])
	sprite.frame = frame
	sprite.centered = false
	sprite.offset = -Vector2(float(info["ax"]), float(info["ay"]))


func _place_sprites() -> void:
	var building_names: Array = _layout["building_sprites"]
	var placements: Array = _layout["placements"]
	for entry: Dictionary in placements:
		var sprite_name: String = entry["sprite"]
		var node: Sprite2D
		if sprite_name == LANTERN_SPRITE:
			var lantern: Lantern = Lantern.new()
			lanterns.append(lantern)
			node = lantern
		else:
			node = Sprite2D.new()
		_apply_sprite(node, sprite_name, 0)
		node.position = tile_to_world(float(entry["i"]), float(entry["j"]))
		if sprite_name in building_names:
			buildings.append(node)
		add_entity(node)


func _draw_ground() -> void:
	var tiles: Texture2D = _texture(TILES_SPRITE)
	var size: int = int(_layout["size"])
	var margin: int = int(_layout["ground_margin"])
	var tile_size: Vector2 = _half_tile * 2.0
	# Back to front, one diagonal at a time, so tile outlines overlap the way the art expects.
	for diagonal: int in range(-2 * margin, 2 * (size + margin) + 1):
		for i: int in range(-margin, size + margin + 1):
			var j: int = diagonal - i
			if j < -margin or j > size + margin:
				continue
			var corner: Vector2 = tile_to_world(i, j)
			var source: Rect2 = Rect2(Vector2(_tile_frame(i, j) * tile_size.x, 0.0), tile_size)
			_ground.draw_texture_rect_region(tiles, Rect2(corner - Vector2(_half_tile.x, 0.0), tile_size), source)


func _texture(sprite_name: String) -> Texture2D:
	if not _textures.has(sprite_name):
		_textures[sprite_name] = load(ART_DIR + sprite_name + ".png")
	return _textures[sprite_name]


func _tile_frame(i: int, j: int) -> int:
	var names: Array = _layout["tile_names"]
	var size: int = int(_layout["size"])
	if j == int(floorf(float(_layout["track_row"]))):
		return names.find(TILE_TRACK)
	if i < 0 or j < 0 or i >= size or j >= size:
		return names.find(TILE_FOREST)
	var rows: Array = _layout["map"]
	var row: String = rows[j]
	var legend: Dictionary = _layout["tile_legend"]
	var tile_name: String = legend[row[i]]
	var flowers: Dictionary = _layout["flower_rule"]
	if tile_name == TILE_GRASS and (i * int(flowers["mul_i"]) + j * int(flowers["mul_j"])) % int(flowers["modulo"]) == 0:
		tile_name = TILE_GRASS_FLOWERS
	return names.find(tile_name)


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("VillageScene: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("VillageScene: %s has no '%s'" % [path, key])
			return {}
	if data.has("placements"):
		var table: Dictionary = data["sprites"]
		var placements: Array = data["placements"]
		for entry: Dictionary in placements:
			if not table.has(entry["sprite"]):
				push_error("VillageScene: %s places unknown sprite '%s'" % [path, entry["sprite"]])
				return {}
	return data
