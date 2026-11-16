extends SceneTree
## One-time bake (scene refactor, step 2): turns the layout's [code]placements[/code] and
## [code]doors[/code] ([code]assets/data/village_layout.json[/code]) into real nodes saved in
## [code]src/village/village_scene.tscn[/code] under the y-sorted [code]World[/code] node, exactly
## where [code]VillageScene._place_sprites[/code] used to build them at runtime:
## lanterns become [Lantern]s, buildings (name or table type in [code]building_sprites[/code])
## become [Building]s carrying their doors, everything else a [PlacedSprite]; rooftop details
## become child [PlacedSprite]s at their building's [code]detail_points[/code]. Placement order is
## kept (the y-sort breaks ties by tree order). Every other node of the scene is kept.
##
## Doors: a door entry ({i, j, door, kind}) goes to the building standing on its tile (i, j);
## when none does (the 2x2 hospital and academy list their footprint's corner tile, the station
## lists three tiles), to the nearest building within [constant DOOR_REACH] tiles whose doors are
## of the same kind or that has none yet. Unmatched doors and buildings without doors are printed.
##
## Run once: [code]godot --headless --path . -s res://tools/scene/bake_objects.gd[/code], then
## remove [code]placements[/code] and [code]doors[/code] from the layout; place objects in the editor
## from then on. Refuses to run when World already holds placed nodes.

const LAYOUT_PATH: String = "res://assets/data/village_layout.json"
const SCENE_PATH: String = "res://src/village/village_scene.tscn"
const PLACED_SCRIPT: GDScript = preload("res://src/village/placed_sprite.gd")
const BUILDING_SCRIPT: GDScript = preload("res://src/village/building.gd")
const LANTERN_SCRIPT: GDScript = preload("res://src/village/lantern.gd")
const LANTERN_SPRITE: String = "lantern"
## Furthest (tiles, from the door tile's centre to the building's anchor) a door is matched.
const DOOR_REACH: float = 1.5
const REQUIRED_KEYS: Array[String] = ["tile_width", "tile_height", "building_sprites", "placements", "doors", "sprites"]


func _initialize() -> void:
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	if not layout is Dictionary:
		push_error("bake_objects: cannot read %s" % LAYOUT_PATH)
		quit(1)
		return
	for key: String in REQUIRED_KEYS:
		if not (layout as Dictionary).has(key):
			push_error("bake_objects: %s has no '%s' (already baked?)" % [LAYOUT_PATH, key])
			quit(1)
			return
	quit(_bake(layout))


func _bake(layout: Dictionary) -> int:
	var packed: PackedScene = load(SCENE_PATH)
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var world: Node2D = root.get_node_or_null("World")
	if world == null:
		push_error("bake_objects: %s has no World node" % SCENE_PATH)
		return 1
	for child: Node in world.get_children():
		if child is Sprite2D:
			push_error("bake_objects: World already holds placed sprites (already baked?)")
			return 1
	var half: Vector2 = Vector2(float(layout["tile_width"]), float(layout["tile_height"])) * 0.5
	var sprites: Dictionary = layout["sprites"]
	var kinds: Array = layout["building_sprites"]
	var buildings: Array[Building] = []
	var building_at: Array[Vector2] = []
	var counts: Dictionary = {}
	var placements: Array = layout["placements"]
	for entry: Dictionary in placements:
		var sprite_name: String = entry["sprite"]
		if not sprites.has(sprite_name):
			push_error("bake_objects: unknown sprite '%s'" % sprite_name)
			return 1
		var i: float = float(entry["i"])
		var j: float = float(entry["j"])
		var node: PlacedSprite
		var kind: String = "prop"
		if sprite_name == LANTERN_SPRITE:
			node = LANTERN_SCRIPT.new()
			kind = "lantern"
		elif sprite_name in kinds or str(sprites[sprite_name].get("type", "")) in kinds:
			node = BUILDING_SCRIPT.new()
			buildings.append(node)
			building_at.append(Vector2(i, j))
			kind = "building"
		else:
			node = PLACED_SCRIPT.new()
		counts[kind] = int(counts.get(kind, 0)) + 1
		node.sprite_name = sprite_name
		node.name = "%s_%d_%d" % [sprite_name, floori(i), floori(j)]
		node.position = Vector2((i - j) * half.x, (i + j) * half.y)
		var points: Array = sprites[sprite_name].get("detail_points", [])
		var details: Array = entry.get("details", [])
		for detail: Dictionary in details:
			var point: int = int(detail["point"])
			var detail_name: String = detail["sprite"]
			if point < 0 or point >= points.size() or not sprites.has(detail_name):
				push_error("bake_objects: '%s' at (%s, %s) has a bad detail %s" % [sprite_name, i, j, detail])
				return 1
			var at: Array = points[point]
			var child: PlacedSprite = PLACED_SCRIPT.new()
			child.sprite_name = detail_name
			child.name = detail_name
			child.position = Vector2(float(at[0]), float(at[1]))
			node.add_child(child, true)
			counts["detail"] = int(counts.get("detail", 0)) + 1
		var sort_y: float = float(sprites[sprite_name].get("sort_y", 0.0))
		if not is_zero_approx(sort_y):
			node.position.y += sort_y
			for child: Node in node.get_children():
				(child as Node2D).position.y -= sort_y
		world.add_child(node, true)
	for node: Node in world.get_children():
		_own(node, root)
	if not _match_doors(layout["doors"], buildings, building_at):
		return 1
	print("bake_objects: placed %s" % counts)
	var out: PackedScene = PackedScene.new()
	var err: Error = out.pack(root)
	if err != OK:
		push_error("bake_objects: pack failed (%d)" % err)
		return 1
	out.take_over_path(SCENE_PATH)
	err = ResourceSaver.save(out, SCENE_PATH)
	root.free()
	if err != OK:
		push_error("bake_objects: cannot save %s (%d)" % [SCENE_PATH, err])
		return 1
	print("bake_objects: saved %s" % SCENE_PATH)
	return 0


func _own(node: Node, root: Node) -> void:
	node.owner = root
	for child: Node in node.get_children():
		_own(child, root)


## Gives each door entry to its building (see the class doc). Returns false on a kind clash.
func _match_doors(doors: Array, buildings: Array[Building], at: Array[Vector2]) -> bool:
	var unmatched: Array[Dictionary] = []
	for door: Dictionary in doors:
		var tile: Vector2i = Vector2i(int(door["i"]), int(door["j"]))
		var found: int = -1
		for k: int in buildings.size():
			if Vector2i(floori(at[k].x), floori(at[k].y)) == tile:
				found = k
		if found < 0:
			unmatched.append(door)
			continue
		if not _give_door(buildings[found], door):
			return false
	for door: Dictionary in unmatched:
		var centre: Vector2 = Vector2(float(door["i"]) + 0.5, float(door["j"]) + 0.5)
		var best: int = -1
		var best_distance: float = DOOR_REACH
		for k: int in buildings.size():
			var kind: String = buildings[k].door_kind
			if kind != "" and kind != str(door["kind"]):
				continue
			var distance: float = centre.distance_to(at[k])
			if distance <= best_distance:
				best_distance = distance
				best = k
		if best < 0:
			print("bake_objects: DOOR MATCHES NO BUILDING: %s" % door)
			continue
		print("bake_objects: door %s -> %s (by distance %.2f)" % [door, buildings[best].name, best_distance])
		_give_door(buildings[best], door)
	var with_door: int = 0
	for building: Building in buildings:
		if building.door_kind.is_empty():
			print("bake_objects: building without a door: %s" % building.name)
		else:
			with_door += 1
	print("bake_objects: %d doors on %d of %d buildings" % [doors.size(), with_door, buildings.size()])
	return true


func _give_door(building: Building, door: Dictionary) -> bool:
	var kind: String = str(door["kind"])
	if building.door_kind != "" and building.door_kind != kind:
		push_error("bake_objects: %s has '%s' and '%s' doors" % [building.name, building.door_kind, kind])
		return false
	building.door_kind = kind
	var tiles: Array[Vector2i] = building.door_tiles.duplicate()
	tiles.append(Vector2i(int(door["door"][0]), int(door["door"][1])))
	building.door_tiles = tiles
	return true
