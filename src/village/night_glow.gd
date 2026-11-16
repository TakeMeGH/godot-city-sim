class_name NightGlow
extends CanvasLayer
## Lamp glow at night (design/game-brief.md, Features item 6; story 006): a soft additive
## radial glow around every lit lantern, two around each building's windows, and one at
## the train's headlamp, fading in as [member Daylight.night_amount] grows (prototype
## drawWorld() glow pass, [code]prototypes/shinobi-station/index.html[/code]).
##
## Why a [CanvasLayer]: the [CanvasModulate] night tint multiplies everything on its own
## canvas, additive sprites included, so glow drawn in the world would be darkened with
## it. This layer sits above the world ([code]layer[/code] 1) with
## [code]follow_viewport_enabled[/code], so it moves with the camera while the tint never
## touches it, matching the prototype, which adds the glow after the tint.
## A story 007 HUD layer should use a higher [code]layer[/code] so the glow stays under it.
##
## Each glow is a centred [Sprite2D] with a generated white radial gradient (alpha 1 at the
## centre to 0 at the edge) and an additive [CanvasItemMaterial], tinted by its colour and
## alpha x k, where k = night_amount / max([code]glow_strength_floor[/code], night_strength).
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (pixels, 0..255 colours):
## [codeblock]
## lantern_glow, headlamp_glow   {offset: [x, y], radius, alpha, color: [r, g, b]}
## window_glows                  list of the same, one glow each per building storey
## storey_px                     how far each storey above the first raises its window glows
## glow_min_night                no glow while night_amount is at or below this
## glow_strength_floor           see k above; (shared) night_strength
## glow_texture_size             gradient texture size (px), scaled to each radius
## [/codeblock]
## Lantern offsets are from the lantern's ground anchor, window offsets from the building's,
## and the headlamp offset from the loco's front on the track ([method Train.front_position]).
##
## Taller buildings (story 009): [code]window_glows[/code] are the first storey's windows. A
## building with more storeys ([method VillageScene.building_storeys], from the sprite table)
## gets the same set again for each storey above, raised [code]storey_px[/code] per storey,
## matching the sheets, which grow upward by one storey height above a fixed ground anchor.
## Rooftop details get no glow.
##
## Other glow sets (story 011): a building whose sprite-table entry has [code]glows[/code] gets
## the tuning list named there instead of [code]window_glows[/code] (the gate: its two post
## lanterns, [code]gate_glows[/code]), brightening with the night like the rest. Offsets are from
## the building's ground anchor ([method VillageScene.ground_anchor], which undoes its sort_y).

const TUNING_KEYS: Array[String] = [
	"lantern_glow", "headlamp_glow", "window_glows", "glow_min_night", "glow_strength_floor",
	"glow_texture_size", "night_strength", "storey_px",
]
const CHANNEL_MAX: float = 255.0
const GRADIENT_CENTRE: Vector2 = Vector2(0.5, 0.5)
const GRADIENT_EDGE: Vector2 = Vector2(1.0, 0.5)
## Sprite-table key naming a building's own glow list in the tuning (story 011).
const GLOWS_KEY: String = "glows"
const WINDOW_GLOWS_KEY: String = "window_glows"

## The village whose lanterns and buildings glow.
@export var village: VillageScene
## The train whose headlamp glows.
@export var train: Train
## The day and night state that sets how bright the glow is.
@export var daylight: Daylight

var _tuning: Dictionary = {}
var _texture: GradientTexture2D
var _material: CanvasItemMaterial
var _lantern_glows: Array[Sprite2D] = []
var _window_glows: Array[Sprite2D] = []
var _window_alphas: Array[float] = []
var _lantern_alpha: float = 0.0
var _headlamp_glow: Sprite2D
var _headlamp_alpha: float = 0.0
var _headlamp_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	visible = false
	set_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _process(_delta: float) -> void:
	var amount: float = daylight.night_amount
	visible = amount > _t("glow_min_night")
	if not visible:
		return
	var k: float = amount / maxf(_t("glow_strength_floor"), _t("night_strength"))
	for n: int in _lantern_glows.size():
		_lantern_glows[n].visible = village.lanterns[n].is_lit
		_lantern_glows[n].modulate.a = _lantern_alpha * k
	for n: int in _window_glows.size():
		_window_glows[n].modulate.a = _window_alphas[n] * k
	_headlamp_glow.visible = train.is_running()
	_headlamp_glow.position = train.front_position() + _headlamp_offset
	_headlamp_glow.modulate.a = _headlamp_alpha * k


func _setup() -> void:
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if _tuning.is_empty():
		get_tree().quit(1)
		return
	_texture = _build_texture(int(_tuning["glow_texture_size"]))
	_material = CanvasItemMaterial.new()
	_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var lantern_spec: Dictionary = _tuning["lantern_glow"]
	_lantern_alpha = float(lantern_spec["alpha"])
	for lantern: VillageScene.Lantern in village.lanterns:
		_lantern_glows.append(_add_glow(lantern_spec, lantern.position))
	var storey_px: float = _t("storey_px")
	for building: Sprite2D in village.buildings:
		var sprite_name: String = village.building_sprite(building)
		var glow_key: String = str(village.sprite_info(sprite_name).get(GLOWS_KEY, WINDOW_GLOWS_KEY))
		if not _tuning.has(glow_key):
			push_error("NightGlow: building '%s' names glows '%s', which the tuning lacks" % [sprite_name, glow_key])
			continue
		var specs: Array = _tuning[glow_key]
		var anchor: Vector2 = village.ground_anchor(building)
		for storey: int in village.building_storeys(building):
			var storey_anchor: Vector2 = anchor + Vector2(0.0, -storey_px * storey)
			for spec: Dictionary in specs:
				_window_glows.append(_add_glow(spec, storey_anchor))
				_window_alphas.append(float(spec["alpha"]))
	var headlamp_spec: Dictionary = _tuning["headlamp_glow"]
	_headlamp_alpha = float(headlamp_spec["alpha"])
	_headlamp_offset = _vec(headlamp_spec["offset"])
	_headlamp_glow = _add_glow(headlamp_spec, Vector2.ZERO)
	set_process(true)


## Adds one glow sprite at [param anchor] + the spec's offset, sized to its radius and
## coloured by its colour (alpha is set each frame).
func _add_glow(spec: Dictionary, anchor: Vector2) -> Sprite2D:
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = _texture
	glow.material = _material
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.position = anchor + _vec(spec["offset"])
	glow.scale = Vector2.ONE * (2.0 * float(spec["radius"]) / float(_texture.width))
	var rgb: Array = spec["color"]
	glow.modulate = Color(float(rgb[0]) / CHANNEL_MAX, float(rgb[1]) / CHANNEL_MAX, float(rgb[2]) / CHANNEL_MAX, 0.0)
	add_child(glow)
	return glow


## White radial gradient, opaque at the centre to transparent at the edge circle.
func _build_texture(size: int) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(Color.WHITE, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = GRADIENT_CENTRE
	texture.fill_to = GRADIENT_EDGE
	texture.width = size
	texture.height = size
	return texture


func _vec(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


func _t(key: String) -> float:
	return float(_tuning[key])


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("NightGlow: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("NightGlow: %s has no '%s'" % [path, key])
			return {}
	return data
