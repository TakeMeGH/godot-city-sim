@tool
class_name PlacedSprite
extends Sprite2D
## A sprite placed in the village scene (a tree, prop, wall or fence piece, lantern, building
## or rooftop detail), saved in [code]village_scene.tscn[/code] under the y-sorted
## [code]World[/code] node (rooftop details under their building).
##
## Set [member sprite_name] and the picture comes from the layout's sprite table
## ([code]assets/data/village_layout.json[/code] key [code]sprites[/code]: sheet
## [code]res://assets/art/<name>.png[/code], [code]frames[/code], anchor [code]ax[/code]/[code]ay[/code]).
## The node's position is its sort point: the ground anchor plus the table's optional
## [code]sort_y[/code] (story 014; the bridge and the gate), and the offset keeps the picture on
## the ground anchor. The derived properties (texture, hframes, offset, centered) are shown
## read-only in the inspector and not saved: the table is the one source, so redrawing a sheet
## or moving its anchor needs no scene edit. The table is read once and cached ([method table]).
##
## Example (in the editor: add a PlacedSprite under World, set Sprite Name to "bench", move it):
## [codeblock]
## var bench: PlacedSprite = PlacedSprite.new()
## bench.sprite_name = "bench"
## bench.position = village.tile_to_world(7.4, 7.6)
## village.add_entity(bench)
## [/codeblock]

const LAYOUT_PATH: String = "res://assets/data/village_layout.json"
const ART_DIR: String = "res://assets/art/"
const SPRITES_KEY: String = "sprites"
const SORT_Y_KEY: String = "sort_y"
## Properties set from the sprite table: read-only in the inspector, never saved.
const DERIVED: Array[StringName] = [&"texture", &"hframes", &"vframes", &"offset", &"centered"]

static var _table: Dictionary = {}
static var _table_loaded: bool = false
static var _textures: Dictionary = {}

## The sprite-table entry this node draws (e.g. "tree_big", "house_block_s2_red_white").
@export var sprite_name: String = "":
	set(value):
		sprite_name = value
		_apply()


## The layout's sprite table (name -> entry), read from the layout file on first use.
## Example: [code]PlacedSprite.table()["lantern"]["frames"][/code]
static func table() -> Dictionary:
	if not _table_loaded:
		_table_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
		if parsed is Dictionary and (parsed as Dictionary).get(SPRITES_KEY) is Dictionary:
			_table = parsed[SPRITES_KEY]
		else:
			push_error("PlacedSprite: %s has no '%s' table" % [LAYOUT_PATH, SPRITES_KEY])
	return _table


## The sprite-table entry for [param name] (empty when there is none).
static func info_of(name: String) -> Dictionary:
	return table().get(name, {})


## The sheet of [param name] ([code]res://assets/art/<name>.png[/code]), loaded once.
static func texture_of(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = load(ART_DIR + name + ".png")
	return _textures[name]


## The table's [code]sort_y[/code] of [param name] (0 when it has none).
static func sort_y_of(name: String) -> float:
	return float(info_of(name).get(SORT_Y_KEY, 0.0))


## Where the picture stands: the node's position less its [code]sort_y[/code].
func ground_anchor() -> Vector2:
	return position - Vector2(0.0, sort_y_of(sprite_name))


func _apply() -> void:
	var info: Dictionary = info_of(sprite_name)
	if info.is_empty():
		texture = null
		return
	texture = texture_of(sprite_name)
	hframes = int(info["frames"])
	centered = false
	offset = -Vector2(float(info["ax"]), float(info["ay"]) + sort_y_of(sprite_name))


func _validate_property(property: Dictionary) -> void:
	if StringName(property["name"]) in DERIVED:
		property["usage"] = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
