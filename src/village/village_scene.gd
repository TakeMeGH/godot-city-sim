@tool
class_name VillageScene
extends Node2D
## The isometric village: ground tiles, buildings, trees, lanterns and street props.
## Camera numbers live in [code]assets/data/village_tuning.json[/code].
##
## The ground is the [TileMapLayer] [code]Ground[/code], painted in the editor and saved in the
## scene (TileSet [code]res://assets/tiles/village_tiles.tres[/code], built from
## [code]tiles.png[/code]). Each tile carries its name in the TileSet custom data layer
## [code]name[/code]; read it with [method tile_name]. Cell (i, j) is the tile whose top corner is
## [code]tile_to_world(i, j)[/code] (layout DIAMOND_DOWN, layer offset (-32, 0)). The village
## proper is the [code]size[/code] x [code]size[/code] square from (0, 0) (layout key
## [code]size[/code], [method is_inside]); the forest ring and the track around it are painted
## cells outside it. The walkable [code]bridge[/code] tile is an alternative of the water tile
## (drawn as water; the bridge sprite covers it).
##
## Buildings, trees, lanterns, wall and fence pieces and props are nodes saved in the scene under
## the y-sorted [code]World[/code] node (scene refactor, step 2; baked once from the old layout
## [code]placements[/code] by [code]tools/scene/bake_objects.gd[/code]): [PlacedSprite]s, [Building]s
## (which carry their own doors, [member doors]) and [Lantern]s. Place, move or delete them in the
## editor; their pictures come from the layout's sprite table ([code]sprites[/code], the art metadata).
## Rooftop details are child [PlacedSprite]s of their building. On [method _ready] this script only
## gathers them ([member buildings], [member lanterns], [member doors], [method placed_sprites]) and
## checks them; nothing is built at load. Villagers, kids, the rooftop runner, the train, event
## critters, the ramen steam, the night glows and the HUD are runtime nodes and only appear when
## the game runs.
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
## placed like any building. The layout's [code]lots[/code] object names the
## rectangles ([code]{i, j, w, h}[/code], in tiles) reserved for later stories: [code]gate[/code],
## [code]market[/code], [code]academy[/code], [code]training[/code], [code]hospital[/code],
## [code]forest[/code] and [code]river[/code]. Lots never overlap each other or a street tile
## (the tuning key [code]lots_on_street_ok[/code] lists the ones that may stand on walkable ground);
## [method _check_lots] reports any that do at startup.
##
## Edge places (story 014): a sprite-table entry may carry
## [code]sort_y[/code] (pixels; negative sorts earlier): the node sorts that far from its ground
## anchor while its picture stays put, so the flat bridge sorts behind the villagers crossing it.
## The 2x2 hospital is a building (its name is in [code]building_sprites[/code]), so its night
## frame switches with the houses. [method _check_tiles] reports unpainted or unnamed map cells.
## The 2x2 academy (story 013) is placed the same way (footprint centre) and is a building; its
## [code]glows[/code] names its lit windows. [method placed_sprites] finds placed props by name
## (the swing tree, whose frames [KidTag] drives).
##
## Building variety (story 009): houses, blocks, towers and shops are sheets named
## [code]<type>_s<storeys>_<roof>_<wall>[/code], each with a sprite-table entry carrying
## [code]type[/code], [code]storeys[/code], [code]roof_height[/code] (rooftop dash) and
## [code]detail_points[/code] ([code][[dx, dy], ...][/code], pixels from the building's ground
## anchor). A sprite is a building when its name, or its table [code]type[/code], is in the
## layout's [code]building_sprites[/code]; such a node must be a [Building]. Rooftop details are
## child [PlacedSprite]s of their building (baked at its [code]detail_points[/code]), so they draw on
## top of it and sort with it. Every variant pick is scene data, nothing is random at runtime.
## [method _check_buildings] reports identical neighbouring buildings at startup.
##
## The main gate (story 011): the [code]gate[/code] sprite stands in the back wall's gap on the
## tuning [code]gate_tile[/code] and is a building (in [code]building_sprites[/code]), so its lit
## night frame switches with the houses; its table entry's [code]sort_y[/code] makes villagers in
## the passage draw in front of it, and its [code]glows[/code] names its lantern glows (NightGlow).
## The tuning [code]village_name[/code] ([member village_name]) is the name the gate's board shows;
## the board is drawn in the art, so a new name means redrawing it. [method _check_gate] reports a
## missing gate building at startup.
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

## The lantern sheet's name (see [Lantern]).
const LANTERN_SPRITE: String = Lantern.DEFAULT_SPRITE
## TileSet custom data layer holding each ground tile's name.
const TILE_NAME_LAYER: String = "name"
## Sprite-table keys for building variants (story 009).
const TYPE_KEY: String = "type"
const STOREYS_KEY: String = "storeys"
## Optional sprite-table key: sort offset in pixels from the ground anchor (story 014).
const SORT_Y_KEY: String = "sort_y"
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
	"size", "tile_width", "tile_height", "building_sprites", "lots", "sprites",
]
const TUNING_KEYS: Array[String] = [
	"pan_speed", "drift_after", "drift_x", "drift_y", "cam_range_x", "cam_range_y",
	"cam_range_up_extra", "start_offset_y", "drift_centre_offset_y", "drift_rate_x",
	"drift_rate_y", "drift_phase_y", "drift_ease", "walk_tiles", "lots_on_street_ok",
	"village_name", "gate_sprite", "gate_tile",
]


## The village's name (tuning [code]village_name[/code]; the gate's board spells it in the art).
var village_name: String = ""
## Every [Lantern] under World, in scene order.
var lanterns: Array[Lantern] = []
## Every [Building] under World (house, block, tower, shop, station, gate, hospital, academy,
## market stall; see [method is_building]), in scene order. Frame 0 is day, frame 1 is night.
## Rooftop details are children of these sprites, not entries here.
var buildings: Array[Sprite2D] = []
## Every door of every [Building], in scene order: [code]{"i": int, "j": int, "door": [di, dj],
## "kind": String}[/code] ((i, j) is the building's anchor tile, "door" the walkable tile in front).
## Example: [code]for door in village.doors: if door["kind"] == "home": ...[/code]
var doors: Array[Dictionary] = []

## The village camera.
@onready var camera: CameraRig = $CameraRig

var _layout: Dictionary = {}
var _sprites: Dictionary = {}
var _half_tile: Vector2 = Vector2.ZERO
## Every [PlacedSprite] directly under World, in scene order.
var _placed: Array[PlacedSprite] = []

@onready var _ground: TileMapLayer = $Ground
@onready var _world: Node2D = $World


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_layout = _load_json(LAYOUT_PATH, LAYOUT_KEYS)
	var tuning: Dictionary = _load_json(TUNING_PATH, TUNING_KEYS)
	if _layout.is_empty() or tuning.is_empty():
		get_tree().quit(1)
		return
	_sprites = _layout["sprites"]
	_half_tile = Vector2(float(_layout["tile_width"]), float(_layout["tile_height"])) * 0.5
	_gather()
	var centre_tile: float = float(_layout["size"]) * 0.5
	camera.setup(tuning, tile_to_world(centre_tile, centre_tile))
	village_name = str(tuning["village_name"])
	_check_lots(tuning)
	_check_gate(tuning)
	_check_placed()
	_check_buildings()
	_check_tiles()
	_check_steam()


## Collects the placed nodes saved under World: [member lanterns], [member buildings] and their
## [member doors]; adds each steaming building's [RamenSteam] (a runtime node, story 012).
func _gather() -> void:
	for child: Node in _world.get_children():
		var placed: PlacedSprite = child as PlacedSprite
		if placed == null:
			continue
		_placed.append(placed)
		if placed is Lantern:
			lanterns.append(placed as Lantern)
		var building: Building = placed as Building
		if building == null:
			continue
		buildings.append(building)
		var tile: Vector2 = tile_of(building)
		for door_tile: Vector2i in building.door_tiles:
			doors.append({"i": floori(tile.x), "j": floori(tile.y), "door": [door_tile.x, door_tile.y], "kind": building.door_kind})
		_add_steam(building)


## World position (pixels) of the tile point (i, j). Tile (0,0)'s top corner is the
## origin; i grows down-right, j grows down-left; a tile's centre is (i + 0.5, j + 0.5).
## Valid once the scene is ready.
## Example: [code]village.tile_to_world(6.0, 6.0)[/code] is the village centre.
func tile_to_world(i: float, j: float) -> Vector2:
	return Vector2((i - j) * _half_tile.x, (i + j) * _half_tile.y)


## Name of the ground tile painted on cell (i, j) (the TileSet custom data
## [code]name[/code], e.g. "cobble", "bridge"); "" when the cell is not painted. Cells outside
## the village square are readable too (forest ring, track). Valid once the scene is ready.
## Example: [code]if village.tile_name(9, 0) == "dirt": ...[/code]
func tile_name(i: int, j: int) -> String:
	var data: TileData = _ground.get_cell_tile_data(Vector2i(i, j))
	return "" if data == null else str(data.get_custom_data(TILE_NAME_LAYER))


## The side of the square village in tiles (layout key [code]size[/code]). Valid once the scene is ready.
func map_size() -> int:
	return int(_layout["size"])


## True when (i, j) is inside the village square (0 <= i, j < [method map_size]).
## Example: [code]village.is_inside(20, 3)[/code] is false on the 20x20 map.
func is_inside(i: int, j: int) -> bool:
	var size: int = map_size()
	return i >= 0 and j >= 0 and i < size and j < size


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


## Every placed node (directly under World) drawing [param sprite_name], in scene order
## (story 013: [KidTag] finds the swing tree this way). Valid once the scene is ready.
## Example: [code]var trees: Array[Sprite2D] = village.placed_sprites("swing_tree")[/code]
func placed_sprites(sprite_name: String) -> Array[Sprite2D]:
	var found: Array[Sprite2D] = []
	for node: PlacedSprite in _placed:
		if is_instance_valid(node) and node.sprite_name == sprite_name:
			found.append(node)
	return found


## Every placed node directly under World (trees, props, walls, lanterns, buildings), in scene
## order. Valid once the scene is ready.
## Example: [code]for node in village.placed_nodes(): print(node.sprite_name, village.tile_of(node))[/code]
func placed_nodes() -> Array[PlacedSprite]:
	return _placed.duplicate()


## The tile point (i, j) a placed node stands on: its ground anchor (see [method ground_anchor])
## mapped back through [method tile_to_world], rounded to 1/100 tile (the old layout precision).
## Example: [code]var tile: Vector2 = village.tile_of(village.lanterns[0])[/code]
func tile_of(node: Sprite2D) -> Vector2:
	var at: Vector2 = ground_anchor(node)
	var u: float = at.x / _half_tile.x
	var v: float = at.y / _half_tile.y
	return Vector2(roundf((v + u) * 50.0) / 100.0, roundf((v - u) * 50.0) / 100.0)


## The sprite-table name a placed node draws ("" for any other node).
func building_sprite(building: Sprite2D) -> String:
	var placed: PlacedSprite = building as PlacedSprite
	return "" if placed == null else placed.sprite_name


## How many storeys a node in [member buildings] has: the table's [code]storeys[/code], or
## [constant BASE_STOREYS] when its entry gives none (the station).
## Example: [code]for building in village.buildings: print(village.building_storeys(building))[/code]
func building_storeys(building: Sprite2D) -> int:
	return int(sprite_info(building_sprite(building)).get(STOREYS_KEY, BASE_STOREYS))


## Where the picture of [param building] (a node in [member buildings], or any placed node) is
## anchored: its position less its sprite-table [code]sort_y[/code] (see [PlacedSprite]).
## Example: [code]glow.position = village.ground_anchor(building) + Vector2(4, -10)[/code]
func ground_anchor(building: Sprite2D) -> Vector2:
	var placed: PlacedSprite = building as PlacedSprite
	return building.position if placed == null else placed.ground_anchor()


## Startup check of the main gate (story 011): a building drawing the tuning [code]gate_sprite[/code]
## must stand on [code]gate_tile[/code], and the sprite must be a building (for its night frame).
## Logs every problem with push_error.
func _check_gate(tuning: Dictionary) -> void:
	var gate_name: String = str(tuning["gate_sprite"])
	var pair: Array = tuning["gate_tile"]
	var tile: Vector2i = Vector2i(floori(float(pair[0])), floori(float(pair[1])))
	if not is_building(gate_name):
		push_error("VillageScene: gate sprite '%s' is not in building_sprites, so it has no night frame" % gate_name)
	for building: Sprite2D in buildings:
		var at: Vector2 = tile_of(building)
		if building_sprite(building) == gate_name and Vector2i(floori(at.x), floori(at.y)) == tile:
			return
	push_error("VillageScene: no '%s' building on the tuning gate_tile %s" % [gate_name, tile])


func _apply_sprite(sprite: Sprite2D, sprite_name: String, frame: int) -> void:
	var info: Dictionary = _sprites[sprite_name]
	sprite.texture = PlacedSprite.texture_of(sprite_name)
	sprite.hframes = int(info["frames"])
	sprite.frame = frame
	sprite.centered = false
	sprite.offset = -Vector2(float(info["ax"]), float(info["ay"]))


## Adds the steam sprite named by [param parent]'s table entry [code]steam[/code] (if any) as a
## [RamenSteam] child at its [code]steam_point[/code] (story 012; a runtime node, never saved). An
## unknown steam sprite is skipped here and reported by [method _check_steam].
func _add_steam(parent: PlacedSprite) -> void:
	var info: Dictionary = sprite_info(parent.sprite_name)
	var steam_name: String = str(info.get(STEAM_KEY, ""))
	if steam_name.is_empty() or not _sprites.has(steam_name):
		return
	var steam: Sprite2D = RAMEN_STEAM_SCRIPT.new() as Sprite2D
	_apply_sprite(steam, steam_name, 0)
	steam.set("frame_seconds", float(sprite_info(steam_name).get(FRAME_SECONDS_KEY, 0.0)))
	var point: Array = info.get(STEAM_POINT_KEY, [0, 0])
	steam.position = Vector2(float(point[0]), float(point[1]) - PlacedSprite.sort_y_of(parent.sprite_name))
	parent.add_child(steam)


## Startup check of the placed nodes: every [PlacedSprite] under World (and every rooftop detail)
## must draw a sprite in the table, and a node is a [Building] exactly when its sprite is a
## building ([method is_building]). Logs every problem with push_error.
func _check_placed() -> void:
	for node: PlacedSprite in _placed:
		if not _sprites.has(node.sprite_name):
			push_error("VillageScene: World/%s draws unknown sprite '%s'" % [node.name, node.sprite_name])
			continue
		if is_building(node.sprite_name) and not node is Building:
			push_error("VillageScene: World/%s ('%s') is a building sprite but not a Building node" % [node.name, node.sprite_name])
		elif node is Building and not is_building(node.sprite_name):
			push_error("VillageScene: World/%s ('%s') is a Building node but not a building sprite" % [node.name, node.sprite_name])
		for child: Node in node.get_children():
			var detail: PlacedSprite = child as PlacedSprite
			if detail != null and not _sprites.has(detail.sprite_name):
				push_error("VillageScene: World/%s/%s draws unknown sprite '%s'" % [node.name, detail.name, detail.sprite_name])


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
## and wall). Unknown detail sprites are reported by [method _check_placed]. Logs every problem
## with push_error.
func _check_buildings() -> void:
	for a: int in buildings.size():
		for b: int in range(a + 1, buildings.size()):
			if building_sprite(buildings[a]) != building_sprite(buildings[b]):
				continue
			var at_a: Vector2 = tile_of(buildings[a])
			var at_b: Vector2 = tile_of(buildings[b])
			var tile_a: Vector2i = Vector2i(floori(at_a.x), floori(at_a.y))
			var tile_b: Vector2i = Vector2i(floori(at_b.x), floori(at_b.y))
			if absi(tile_a.x - tile_b.x) <= NEIGHBOUR_TILES and absi(tile_a.y - tile_b.y) <= NEIGHBOUR_TILES:
				push_error("VillageScene: identical neighbouring buildings '%s' on tiles %s and %s" % [building_sprite(buildings[a]), tile_a, tile_b])


## Startup check of the layout's reserved lots: each must lie inside the map, none may
## overlap another, and none may cover a walkable tile unless the tuning key
## [code]lots_on_street_ok[/code] allows it. Logs every problem with push_error.
func _check_lots(tuning: Dictionary) -> void:
	var size: int = int(_layout["size"])
	var lots: Dictionary = _layout["lots"]
	var walk_tiles: Array = tuning["walk_tiles"]
	var allowed: Array = tuning["lots_on_street_ok"]
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
			for i: int in range(rect.position.x, rect.end.x):
				if tile_name(i, j) in walk_tiles:
					push_error("VillageScene: lot '%s' covers the walkable tile (%d, %d)" % [lot_name, i, j])
	var names: Array = rects.keys()
	for a: int in names.size():
		for b: int in range(a + 1, names.size()):
			var rect_a: Rect2i = rects[names[a]]
			var rect_b: Rect2i = rects[names[b]]
			if rect_a.intersects(rect_b):
				push_error("VillageScene: lots '%s' and '%s' overlap" % [names[a], names[b]])


## Startup check of the ground (story 014, a TileMapLayer since the ground refactor): every
## cell of the village square must be painted with a named tile. Logs every problem with push_error.
func _check_tiles() -> void:
	var size: int = map_size()
	for j: int in size:
		for i: int in size:
			if tile_name(i, j).is_empty():
				push_error("VillageScene: ground cell (%d, %d) is unpainted or its tile has no '%s'" % [i, j, TILE_NAME_LAYER])


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
	return data
