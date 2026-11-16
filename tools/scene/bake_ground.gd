extends SceneTree
## One-time bake (ground refactor, step 1): builds the isometric TileSet
## [code]res://assets/tiles/village_tiles.tres[/code] from [code]assets/art/tiles.png[/code] and
## replaces the old drawn [code]Ground[/code] Node2D of the village scene with a painted
## [TileMapLayer], tile for tile what [code]VillageScene._draw_ground[/code] used to draw from
## the layout's [code]map[/code], [code]tile_legend[/code], [code]flower_rule[/code],
## [code]tile_frames[/code], [code]ground_margin[/code] and [code]track_row[/code].
## Every other node of the scene is kept: the scene is instantiated, the node swapped, packed
## and saved. After the bake those layout keys are removed, so this script cannot run again;
## paint the ground in the editor from then on.
##
## Run: [code]godot --headless --path . -s res://tools/scene/bake_ground.gd[/code]

const LAYOUT_PATH: String = "res://assets/data/village_layout.json"
const SCENE_PATH: String = "res://src/village/village_scene.tscn"
const TILESET_PATH: String = "res://assets/tiles/village_tiles.tres"
const TILES_TEXTURE: String = "res://assets/art/tiles.png"
const NAME_LAYER: String = "name"
const SOURCE_ID: int = 0
const REQUIRED_KEYS: Array[String] = [
	"size", "tile_width", "tile_height", "ground_margin", "track_row", "flower_rule", "tile_names",
	"tile_legend", "map",
]


func _init() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	for key: String in REQUIRED_KEYS:
		if not layout.has(key):
			push_error("bake_ground: %s has no '%s' (already baked?)" % [LAYOUT_PATH, key])
			quit(1)
			return
	var tile_set: TileSet = _build_tile_set(layout)
	var err: Error = ResourceSaver.save(tile_set, TILESET_PATH)
	if err != OK:
		push_error("bake_ground: cannot save %s (%d)" % [TILESET_PATH, err])
		quit(1)
		return
	tile_set = ResourceLoader.load(TILESET_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
	var ground: TileMapLayer = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	if not _paint(ground, layout):
		quit(1)
		return
	quit(_swap_into_scene(ground))


func _build_tile_set(layout: Dictionary) -> TileSet:
	var names: Array = layout["tile_names"]
	var size: Vector2i = Vector2i(int(layout["tile_width"]), int(layout["tile_height"]))
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = size
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, NAME_LAYER)
	tile_set.set_custom_data_layer_type(0, TYPE_STRING)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load(TILES_TEXTURE)
	source.texture_region_size = size
	tile_set.add_source(source, SOURCE_ID)
	for k: int in names.size():
		source.create_tile(Vector2i(k, 0))
		source.get_tile_data(Vector2i(k, 0), 0).set_custom_data(NAME_LAYER, str(names[k]))
	# Aliases (tile_frames, e.g. bridge -> water): an alternative tile of the frame it draws with.
	var aliases: Dictionary = layout.get("tile_frames", {})
	for alias: String in aliases:
		var coords: Vector2i = Vector2i(names.find(aliases[alias]), 0)
		var alt: int = source.create_alternative_tile(coords)
		source.get_tile_data(coords, alt).set_custom_data(NAME_LAYER, alias)
	return tile_set


## The atlas cell [coords, alternative] whose custom "name" is [param tile_name]; empty when none.
func _tile_for(source: TileSetAtlasSource, tile_name: String) -> Array:
	for t: int in source.get_tiles_count():
		var coords: Vector2i = source.get_tile_id(t)
		for a: int in source.get_alternative_tiles_count(coords):
			var alt: int = source.get_alternative_tile_id(coords, a)
			if str(source.get_tile_data(coords, alt).get_custom_data(NAME_LAYER)) == tile_name:
				return [coords, alt]
	return []


func _paint(ground: TileMapLayer, layout: Dictionary) -> bool:
	var half: Vector2 = Vector2(float(layout["tile_width"]), float(layout["tile_height"])) * 0.5
	# Old drawing: tile (i, j)'s picture is the 64x32 rect whose top centre is ((i-j)*hw, (i+j)*hh),
	# so its centre is that plus (0, hh). The layer draws a tile centred on map_to_local(cell).
	var offset: Vector2 = Vector2.ZERO
	var probes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(5, -3), Vector2i(-10, 30)]
	for probe: Vector2i in probes:
		var old_centre: Vector2 = Vector2((probe.x - probe.y) * half.x, (probe.x + probe.y) * half.y + half.y)
		var here: Vector2 = old_centre - ground.map_to_local(probe)
		if probe == Vector2i.ZERO:
			offset = here
		elif not here.is_equal_approx(offset):
			push_error("bake_ground: layout axes do not match (cell %s offset %s vs %s)" % [probe, here, offset])
			return false
	print("bake_ground: map_to_local (0,0)=%s (1,0)=%s (0,1)=%s, layer offset %s" % [
		ground.map_to_local(Vector2i(0, 0)), ground.map_to_local(Vector2i(1, 0)),
		ground.map_to_local(Vector2i(0, 1)), offset])
	ground.position = offset
	var source: TileSetAtlasSource = ground.tile_set.get_source(SOURCE_ID)
	var size: int = int(layout["size"])
	var margin: int = int(layout["ground_margin"])
	var track_j: int = floori(float(layout["track_row"]))
	var rows: Array = layout["map"]
	var legend: Dictionary = layout["tile_legend"]
	var flowers: Dictionary = layout["flower_rule"]
	var count: int = 0
	for j: int in range(-margin, size + margin + 1):
		for i: int in range(-margin, size + margin + 1):
			var tile_name: String
			if j == track_j:
				tile_name = "track"
			elif i < 0 or j < 0 or i >= size or j >= size:
				tile_name = "forest"
			else:
				var row: String = rows[j]
				tile_name = legend[row[i]]
				if tile_name == "grass" and (i * int(flowers["mul_i"]) + j * int(flowers["mul_j"])) % int(flowers["modulo"]) == 0:
					tile_name = "grass_flowers"
			var cell: Array = _tile_for(source, tile_name)
			if cell.is_empty():
				push_error("bake_ground: no tile named '%s'" % tile_name)
				return false
			ground.set_cell(Vector2i(i, j), SOURCE_ID, cell[0], cell[1])
			count += 1
	print("bake_ground: painted %d cells" % count)
	return true


func _child_names(node: Node) -> PackedStringArray:
	var out: PackedStringArray = []
	for child: Node in node.get_children():
		out.append("%s:%s" % [child.name, child.get_class()])
	return out


func _swap_into_scene(ground: TileMapLayer) -> int:
	var packed: PackedScene = load(SCENE_PATH)
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var old: Node = root.get_node_or_null("Ground")
	if old == null:
		push_error("bake_ground: %s has no Ground node" % SCENE_PATH)
		return 1
	print("bake_ground: children before ", _child_names(root))
	var index: int = old.get_index()
	root.remove_child(old)
	old.free()
	root.add_child(ground)
	root.move_child(ground, index)
	ground.owner = root
	print("bake_ground: children after  ", _child_names(root))
	var out: PackedScene = PackedScene.new()
	var err: Error = out.pack(root)
	if err != OK:
		push_error("bake_ground: pack failed (%d)" % err)
		return 1
	out.take_over_path(SCENE_PATH)
	err = ResourceSaver.save(out, SCENE_PATH)
	root.free()
	if err != OK:
		push_error("bake_ground: cannot save %s (%d)" % [SCENE_PATH, err])
		return 1
	print("bake_ground: saved %s" % SCENE_PATH)
	return 0
