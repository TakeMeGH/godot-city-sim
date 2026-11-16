@tool
class_name VillageScene
extends Node2D
## The isometric village: ground tiles, buildings, trees, lanterns and street props,
## built from [code]assets/data/village_layout.json[/code]. Camera numbers live in
## [code]assets/data/village_tuning.json[/code].
##
## In the editor this script runs too, so the scene view shows the ground and every
## placement (a preview: those sprites have no owner, so they are never saved into the
## scene). After editing the layout file, press [b]Rebuild preview[/b] in the inspector.
## Villagers, the train and the other runtime nodes only appear when the game runs.
##
## Every sprite's node origin is its ground anchor, so a node placed at
## [method tile_to_world] stands on that tile point. Everything that must sort against
## the buildings (villagers, train cars, props) lives in the y-sorted [code]World[/code]
## node: add it with [method add_entity] and it is drawn in front of or behind the
## buildings by its y position.
##
## The layout is a 20x20 village in districts (story 008): a main street from the gate gap
## in the back wall (row j=0) to the central plaza, cross streets splitting the housing
## blocks, the station platform and track along the front (high j) edge, and a ring of wall
## pieces ([code]wall_i[/code] along i, [code]wall_j[/code] along j, [code]wall_corner[/code])
## placed from the layout like any building. The layout's [code]lots[/code] object names the
## rectangles ([code]{i, j, w, h}[/code], in tiles) reserved for later stories: [code]gate[/code],
## [code]market[/code], [code]academy[/code], [code]training[/code], [code]hospital[/code],
## [code]forest[/code] and [code]river[/code]. Lots never overlap each other or a street tile
## (the tuning key [code]lots_on_street_ok[/code] lists the ones that may stand on walkable ground);
## [method _check_lots] reports any that do at startup.
##
## Edge places (story 014): the layout's optional [code]tile_frames[/code] maps a tile name with
## no frame of its own to the frame it is drawn with (the walkable [code]bridge[/code] tile is
## drawn as water; the bridge sprite covers it). A sprite-table entry may carry
## [code]sort_y[/code] (pixels; negative sorts earlier): the node sorts that far from its ground
## anchor while its picture stays put, so the flat bridge sorts behind the villagers crossing it.
## The 2x2 hospital is a building (its name is in [code]building_sprites[/code]), so its night
## frame switches with the houses. [method _check_tiles] reports legend tiles without a frame.
## The 2x2 academy (story 013) is placed the same way (footprint centre) and is a building; its
## [code]glows[/code] names its lit windows. [method placed_sprites] finds placed props by name
## (the swing tree, whose frames [KidTag] drives).
##
## Building variety (story 009): houses, blocks, towers and shops are sheets named
## [code]<type>_s<storeys>_<roof>_<wall>[/code], each with a sprite-table entry carrying
## [code]type[/code], [code]storeys[/code], [code]roof_height[/code] (rooftop dash) and
## [code]detail_points[/code] ([code][[dx, dy], ...][/code], pixels from the building's ground
## anchor). A sprite is a building when its name, or its table [code]type[/code], is in the
## layout's [code]building_sprites[/code]. A placement may list rooftop details,
## [code]"details": [{"sprite": "roof_tank_round", "point": 0}][/code]: each becomes a child
## [Sprite2D] of its building at that detail point (its own ground anchor from the table), so it
## draws on top of its building and sorts with it, in the editor preview too. Every variant pick
## is layout data, nothing is random at runtime. [method _check_buildings] reports identical
## neighbouring buildings and bad details at startup.
##
## The main gate (story 011): the [code]gate[/code] sprite stands in the back wall's gap on the
## tuning [code]gate_tile[/code] and is a building (in [code]building_sprites[/code]), so its lit
## night frame switches with the houses; its table entry's [code]sort_y[/code] makes villagers in
## the passage draw in front of it, and its [code]glows[/code] names its lantern glows (NightGlow).
## The tuning [code]village_name[/code] ([member village_name]) is the name the gate's board shows;
## the board is drawn in the art, so a new name means redrawing it. [method _check_gate] reports a
## missing gate placement at startup.
##
## The market street (story 012): the ramen stand, flower shop and tea house are buildings (in
## [code]building_sprites[/code]), so their lit night frames switch with the houses (the stand's
## night frame is "closed, lantern lit"; its [code]glows[/code] names its lantern glow). A sprite-table
## entry with [code]steam[/code] gets that sprite as a [RamenSteam] child at its
## [code]steam_point[/code] (pixels from the ground anchor), swapping frames every steam entry's
## [code]frame_seconds[/code] while the stand is open and hidden while it shows its night frame.
## The stand's seats are the layout's [code]ramen_seats[/code] (tile points, used by
## [VillagerRoutines]). [method _check_steam] reports a steam sprite missing from the table.
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
## Sprite-table and placement keys for building variants and rooftop details (story 009).
const TYPE_KEY: String = "type"
const STOREYS_KEY: String = "storeys"
const DETAIL_POINTS_KEY: String = "detail_points"
const DETAILS_KEY: String = "details"
const DETAIL_SPRITE_KEY: String = "sprite"
const DETAIL_POINT_KEY: String = "point"
## Optional layout key: tile name -> the tile name whose frame draws it (story 014).
const TILE_FRAMES_KEY: String = "tile_frames"
## Optional sprite-table key: sort offset in pixels from the ground anchor (story 014).
const SORT_Y_KEY: String = "sort_y"
const FRAMES_KEY: String = "frames"
## Sprite-table keys of the ramen stand's steam (story 012).
const STEAM_KEY: String = "steam"
const STEAM_POINT_KEY: String = "steam_point"
const FRAME_SECONDS_KEY: String = "frame_seconds"
const RAMEN_STEAM_SCRIPT: GDScript = preload("res://src/village/ramen_steam.gd")
## Storeys of a building whose table entry gives none (the station, the original sheets).
const BASE_STOREYS: int = 1
## Neighbouring buildings are at most this many tiles apart on each axis (8-neighbourhood).
const NEIGHBOUR_TILES: int = 1

const LAYOUT_KEYS: Array[String] = [
	"size", "tile_width", "tile_height", "ground_margin", "track_row", "flower_rule",
	"building_sprites", "tile_names", "tile_legend", "lots", "map", "placements", "doors", "sprites",
]
const TUNING_KEYS: Array[String] = [
	"pan_speed", "drift_after", "drift_x", "drift_y", "cam_range_x", "cam_range_y",
	"cam_range_up_extra", "start_offset_y", "drift_centre_offset_y", "drift_rate_x",
	"drift_rate_y", "drift_phase_y", "drift_ease", "walk_tiles", "lots_on_street_ok",
	"village_name", "gate_sprite", "gate_tile",
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


## The village's name (tuning [code]village_name[/code]; the gate's board spells it in the art).
var village_name: String = ""
## Every lantern in the village.
var lanterns: Array[Lantern] = []
## Every house, block, tower, shop and station sprite, every variant included (see
## [method is_building]). Frame 0 is day, frame 1 is night. Rooftop details are children of
## these sprites, not entries here.
var buildings: Array[Sprite2D] = []
## Editor only: reloads village_layout.json and redraws the scene-view preview.
@export_tool_button("Rebuild preview", "Reload") var rebuild_preview: Callable = _build_village

## The village camera.
@onready var camera: CameraRig = $CameraRig

var _layout: Dictionary = {}
var _sprites: Dictionary = {}
var _half_tile: Vector2 = Vector2.ZERO
var _textures: Dictionary = {}
## The sprites built from the layout's placements, so a rebuild can remove them.
var _placed: Array[Node] = []
## Building node -> the sprite-table name it was built from.
var _building_names: Dictionary = {}
## Placed node -> the sprite-table name it was built from (every placement, story 013).
var _placed_names: Dictionary = {}

@onready var _ground: Node2D = $Ground
@onready var _world: Node2D = $World


func _ready() -> void:
	if Engine.is_editor_hint():
		_build_village()
		return
	var tuning: Dictionary = _load_json(TUNING_PATH, TUNING_KEYS)
	if not _build_village() or tuning.is_empty():
		get_tree().quit(1)
		return
	var centre_tile: float = float(_layout["size"]) * 0.5
	camera.setup(tuning, tile_to_world(centre_tile, centre_tile))
	village_name = str(tuning["village_name"])
	_check_lots(tuning)
	_check_gate(tuning)
	_check_buildings()
	_check_tiles()
	_check_steam()


## Loads the layout, draws the ground and places every sprite (again, replacing the
## last build). Returns false when the layout file is missing or incomplete.
func _build_village() -> bool:
	if _world == null or _ground == null:
		return false
	_layout = _load_json(LAYOUT_PATH, LAYOUT_KEYS)
	if _layout.is_empty():
		return false
	_sprites = _layout["sprites"]
	_textures.clear()
	_half_tile = Vector2(float(_layout["tile_width"]), float(_layout["tile_height"])) * 0.5
	if not _ground.draw.is_connected(_draw_ground):
		_ground.draw.connect(_draw_ground)
	_ground.queue_redraw()
	for node: Node in _placed:
		if is_instance_valid(node):
			node.queue_free()
	_placed.clear()
	_placed_names.clear()
	lanterns.clear()
	buildings.clear()
	_building_names.clear()
	_place_sprites()
	return true


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


## The layout's sprite-table entry for [param sprite_name] (empty when there is none).
## Example: [code]village.sprite_info("house_block_s2_red_white")["roof_height"][/code]
func sprite_info(sprite_name: String) -> Dictionary:
	return _sprites.get(sprite_name, {})


## True when [param sprite_name] is a building: its name, or its sprite-table
## [code]type[/code], is in the layout's [code]building_sprites[/code].
## Example: [code]village.is_building("tower_s2_slate_cream")[/code] is true.
func is_building(sprite_name: String) -> bool:
	var kinds: Array = _layout["building_sprites"]
	return sprite_name in kinds or str(sprite_info(sprite_name).get(TYPE_KEY, "")) in kinds


## Every sprite placed from the layout's placements as [param sprite_name], in placement order
## (story 013: [KidTag] finds the swing tree this way). Valid once the scene is ready.
## Example: [code]var trees: Array[Sprite2D] = village.placed_sprites("swing_tree")[/code]
func placed_sprites(sprite_name: String) -> Array[Sprite2D]:
	var found: Array[Sprite2D] = []
	for node: Node in _placed:
		if is_instance_valid(node) and str(_placed_names.get(node, "")) == sprite_name:
			found.append(node as Sprite2D)
	return found


## The sprite-table name a node in [member buildings] was built from ("" for any other node).
func building_sprite(building: Sprite2D) -> String:
	return _building_names.get(building, "")


## How many storeys a node in [member buildings] has: the table's [code]storeys[/code], or
## [constant BASE_STOREYS] when its entry gives none (the station).
## Example: [code]for building in village.buildings: print(village.building_storeys(building))[/code]
func building_storeys(building: Sprite2D) -> int:
	return int(sprite_info(building_sprite(building)).get(STOREYS_KEY, BASE_STOREYS))


## Where the picture of [param building] (a node in [member buildings]) is anchored: its
## position less its sprite-table [code]sort_y[/code] (see [method _apply_sort_y]).
## Example: [code]glow.position = village.ground_anchor(building) + Vector2(4, -10)[/code]
func ground_anchor(building: Sprite2D) -> Vector2:
	var sort_y: float = float(sprite_info(building_sprite(building)).get(SORT_Y_KEY, 0.0))
	return building.position - Vector2(0.0, sort_y)


## Startup check of the main gate (story 011): a placement of the tuning [code]gate_sprite[/code]
## must stand on [code]gate_tile[/code], and the sprite must be a building (for its night frame).
## Logs every problem with push_error.
func _check_gate(tuning: Dictionary) -> void:
	var gate_name: String = str(tuning["gate_sprite"])
	var pair: Array = tuning["gate_tile"]
	var tile: Vector2i = Vector2i(floori(float(pair[0])), floori(float(pair[1])))
	if not is_building(gate_name):
		push_error("VillageScene: gate sprite '%s' is not in building_sprites, so it has no night frame" % gate_name)
	var placements: Array = _layout["placements"]
	for entry: Dictionary in placements:
		if entry["sprite"] == gate_name and Vector2i(floori(float(entry["i"])), floori(float(entry["j"]))) == tile:
			return
	push_error("VillageScene: no '%s' placement on the tuning gate_tile %s" % [gate_name, tile])


func _apply_sprite(sprite: Sprite2D, sprite_name: String, frame: int) -> void:
	var info: Dictionary = _sprites[sprite_name]
	sprite.texture = _texture(sprite_name)
	sprite.hframes = int(info["frames"])
	sprite.frame = frame
	sprite.centered = false
	sprite.offset = -Vector2(float(info["ax"]), float(info["ay"]))


func _place_sprites() -> void:
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
		if is_building(sprite_name):
			buildings.append(node)
			_building_names[node] = sprite_name
		_add_details(node, sprite_name, entry)
		_add_steam(node, sprite_name)
		_apply_sort_y(node, sprite_name)
		_placed.append(node)
		_placed_names[node] = sprite_name
		add_entity(node)


## Moves [param node]'s sort point by its sprite-table [code]sort_y[/code] while keeping the
## picture where it was: the node moves, its offset and its children move back (story 014).
func _apply_sort_y(node: Sprite2D, sprite_name: String) -> void:
	var sort_y: float = float(sprite_info(sprite_name).get(SORT_Y_KEY, 0.0))
	if is_zero_approx(sort_y):
		return
	node.position.y += sort_y
	node.offset.y -= sort_y
	for child: Node in node.get_children():
		if child is Node2D:
			(child as Node2D).position.y -= sort_y


## Adds the placement's rooftop details as child sprites of [param parent], each at its
## building's detail point. A detail with an unknown sprite or point is skipped here and
## reported by [method _check_buildings].
func _add_details(parent: Sprite2D, sprite_name: String, entry: Dictionary) -> void:
	var details: Array = entry.get(DETAILS_KEY, [])
	var points: Array = sprite_info(sprite_name).get(DETAIL_POINTS_KEY, [])
	for detail: Dictionary in details:
		var point: int = int(detail[DETAIL_POINT_KEY])
		var detail_name: String = detail[DETAIL_SPRITE_KEY]
		if point < 0 or point >= points.size() or not _sprites.has(detail_name):
			continue
		var at: Array = points[point]
		var sprite: Sprite2D = create_sprite(detail_name, 0)
		sprite.position = Vector2(float(at[0]), float(at[1]))
		parent.add_child(sprite)


## Adds the steam sprite named by [param sprite_name]'s table entry [code]steam[/code] (if any)
## as a [RamenSteam] child of [param parent] at its [code]steam_point[/code] (story 012). An
## unknown steam sprite is skipped here and reported by [method _check_steam].
func _add_steam(parent: Sprite2D, sprite_name: String) -> void:
	var steam_name: String = str(sprite_info(sprite_name).get(STEAM_KEY, ""))
	if steam_name.is_empty() or not _sprites.has(steam_name):
		return
	var steam: Sprite2D = RAMEN_STEAM_SCRIPT.new() as Sprite2D
	_apply_sprite(steam, steam_name, 0)
	steam.set("frame_seconds", float(sprite_info(steam_name).get(FRAME_SECONDS_KEY, 0.0)))
	var point: Array = sprite_info(sprite_name).get(STEAM_POINT_KEY, [0, 0])
	steam.position = Vector2(float(point[0]), float(point[1]))
	parent.add_child(steam)


## Startup check of the steam (story 012): every sprite-table [code]steam[/code] must name a sprite
## in the table and come with a [code]steam_point[/code]. Logs every problem with push_error.
func _check_steam() -> void:
	for sprite_name: String in _sprites:
		var info: Dictionary = _sprites[sprite_name]
		if not info.has(STEAM_KEY):
			continue
		if not _sprites.has(str(info[STEAM_KEY])):
			push_error("VillageScene: '%s' names unknown steam sprite '%s'" % [sprite_name, info[STEAM_KEY]])
		if not info.has(STEAM_POINT_KEY):
			push_error("VillageScene: '%s' has a steam sprite but no '%s'" % [sprite_name, STEAM_POINT_KEY])


## Startup check of the building variants (story 009): no two buildings on neighbouring
## tiles (8-neighbourhood) may use the same sprite (a variant name fixes type, storeys, roof
## and wall), and every rooftop detail must name a known sprite and an existing detail point
## of its building. Logs every problem with push_error.
func _check_buildings() -> void:
	var placements: Array = _layout["placements"]
	var placed: Array[Dictionary] = []
	for entry: Dictionary in placements:
		var sprite_name: String = entry["sprite"]
		var points: Array = sprite_info(sprite_name).get(DETAIL_POINTS_KEY, [])
		var details: Array = entry.get(DETAILS_KEY, [])
		for detail: Dictionary in details:
			var point: int = int(detail.get(DETAIL_POINT_KEY, -1))
			var detail_name: String = str(detail.get(DETAIL_SPRITE_KEY, ""))
			if not _sprites.has(detail_name):
				push_error("VillageScene: '%s' at (%s, %s) has unknown detail sprite '%s'" % [sprite_name, entry["i"], entry["j"], detail_name])
			if point < 0 or point >= points.size():
				push_error("VillageScene: '%s' at (%s, %s) has no detail point %d (it has %d)" % [sprite_name, entry["i"], entry["j"], point, points.size()])
		if is_building(sprite_name):
			placed.append(entry)
	for a: int in placed.size():
		for b: int in range(a + 1, placed.size()):
			if placed[a]["sprite"] != placed[b]["sprite"]:
				continue
			var tile_a: Vector2i = Vector2i(floori(float(placed[a]["i"])), floori(float(placed[a]["j"])))
			var tile_b: Vector2i = Vector2i(floori(float(placed[b]["i"])), floori(float(placed[b]["j"])))
			if absi(tile_a.x - tile_b.x) <= NEIGHBOUR_TILES and absi(tile_a.y - tile_b.y) <= NEIGHBOUR_TILES:
				push_error("VillageScene: identical neighbouring buildings '%s' on tiles %s and %s" % [placed[a]["sprite"], tile_a, tile_b])


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


## Startup check of the layout's reserved lots: each must lie inside the map, none may
## overlap another, and none may cover a walkable tile unless the tuning key
## [code]lots_on_street_ok[/code] allows it. Logs every problem with push_error.
func _check_lots(tuning: Dictionary) -> void:
	var size: int = int(_layout["size"])
	var lots: Dictionary = _layout["lots"]
	var walk_tiles: Array = tuning["walk_tiles"]
	var allowed: Array = tuning["lots_on_street_ok"]
	var legend: Dictionary = _layout["tile_legend"]
	var rows: Array = _layout["map"]
	var rects: Dictionary = {}
	for lot_name: String in lots:
		var lot: Dictionary = lots[lot_name]
		var rect: Rect2i = Rect2i(int(lot["i"]), int(lot["j"]), int(lot["w"]), int(lot["h"]))
		rects[lot_name] = rect
		if not Rect2i(0, 0, size, size).encloses(rect):
			push_error("VillageScene: lot '%s' %s is outside the %dx%d map" % [lot_name, rect, size, size])
			continue
		if lot_name in allowed:
			continue
		for j: int in range(rect.position.y, rect.end.y):
			var row: String = rows[j]
			for i: int in range(rect.position.x, rect.end.x):
				if legend[row[i]] in walk_tiles:
					push_error("VillageScene: lot '%s' covers the walkable tile (%d, %d)" % [lot_name, i, j])
	var names: Array = rects.keys()
	for a: int in names.size():
		for b: int in range(a + 1, names.size()):
			var rect_a: Rect2i = rects[names[a]]
			var rect_b: Rect2i = rects[names[b]]
			if rect_a.intersects(rect_b):
				push_error("VillageScene: lots '%s' and '%s' overlap" % [names[a], names[b]])


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
	return _frame_of(tile_name)


## The tiles.png frame for [param tile_name], through the layout's optional
## [code]tile_frames[/code] alias (e.g. "bridge" draws with the "water" frame); -1 when none.
func _frame_of(tile_name: String) -> int:
	var names: Array = _layout["tile_names"]
	var aliases: Dictionary = _layout.get(TILE_FRAMES_KEY, {})
	return names.find(str(aliases.get(tile_name, tile_name)))


## Startup check of the ground tiles (story 014): tile_names may not list more frames than
## tiles.png has, and every legend tile must draw with one of them (directly or through
## [code]tile_frames[/code]). Logs every problem with push_error.
func _check_tiles() -> void:
	var names: Array = _layout["tile_names"]
	var sheet_frames: int = int(sprite_info(TILES_SPRITE).get(FRAMES_KEY, 0))
	if names.size() > sheet_frames:
		push_error("VillageScene: tile_names lists %d tiles but '%s' has %d frames" % [names.size(), TILES_SPRITE, sheet_frames])
	var legend: Dictionary = _layout["tile_legend"]
	for key: String in legend:
		var frame: int = _frame_of(str(legend[key]))
		if frame < 0 or frame >= sheet_frames:
			push_error("VillageScene: map tile '%s' (%s) has no frame in '%s'" % [key, legend[key], TILES_SPRITE])


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
