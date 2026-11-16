class_name Daylight
extends Node
## Day and night (design/game-brief.md, Features item 6; story 006). Each frame it reads
## the [DayClock] and works out [member daylight] (1 by day, fading through dawn and dusk,
## 0 at night) and [member warmth] (the warm glow around dawn and dusk), then:
## [br]- drives the [CanvasModulate] [member tint]: a multiply tint that goes blue-purple
## by [code]night_tint[/code] x [member night_amount] and warm by [code]warm_tint[/code] x
## [member warmth] (each tint is how much is taken off each 0..255 channel at full strength);
## [br]- once [member daylight] drops below [code]night_below_daylight[/code], shows every
## building's lit-window frame (frame 1) and the train's night frames ([member Train.night]).
## [br]Matches the browser prototype's daylight(), warmth() and night tint
## ([code]prototypes/shinobi-station/index.html[/code]). The lamp glow is [NightGlow].
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (times of day 0..1):
## [codeblock]
## night_strength                            how dark the night gets (night_amount at full night)
## night_tint, warm_tint                     [r, g, b] taken off 255 at full night / full warmth
## daylight_dawn_start, daylight_dawn_end    dawn fade, relative to wake_time
## daylight_dusk_start, daylight_dusk_end    dusk fade, relative to home_time
## warmth_dawn_offset, warmth_dusk_offset    warmth peaks, relative to wake_time / home_time
## warmth_width                              warmth falls to 0 this far from a peak
## night_below_daylight                      lit windows and night train below this daylight
## tint_min                                  no tint while night_amount and warmth are both below this
## [/codeblock]
##
## Example (story 007's HUD): [code]label.text = "night" if daylight.is_night else "day"[/code]

## Emitted when the lit-window frames switch on ([param is_night] true) or off.
signal night_changed(is_night: bool)

const TUNING_KEYS: Array[String] = [
	"night_strength", "night_tint", "warm_tint", "daylight_dawn_start", "daylight_dawn_end",
	"daylight_dusk_start", "daylight_dusk_end", "warmth_dawn_offset", "warmth_dusk_offset",
	"warmth_width", "night_below_daylight", "tint_min",
]
## Building sheets: frame 0 is day, frame 1 has lit windows.
const DAY_FRAME: int = 0
const LIT_FRAME: int = 1
const CHANNEL_MAX: float = 255.0

## The village whose buildings switch to lit windows.
@export var village: VillageScene
## The day clock that sets the time of day.
@export var clock: DayClock
## The train that switches to its night frames.
@export var train: Train
## The multiply tint over the world (night and dusk colour).
@export var tint: CanvasModulate

## 1 by day, 0 at night, fading linearly through dawn and dusk.
var daylight: float = 1.0
## How dark it is: (1 - [member daylight]) x [code]night_strength[/code].
var night_amount: float = 0.0
## Dusk and dawn glow, 0..1, peaking near [code]home_time[/code] and [code]wake_time[/code].
var warmth: float = 0.0
## True while the lit-window and night train frames show.
var is_night: bool = false

var _tuning: Dictionary = {}
var _night_tint: Color = Color.BLACK
var _warm_tint: Color = Color.BLACK


func _ready() -> void:
	set_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _process(_delta: float) -> void:
	_update(false)


## Daylight at time of day [param t]: 1 between dawn and dusk, 0 at night, linear fades
## (prototype daylight()).
## Example: [code]daylight.daylight_at(0.5)[/code] is 1.0 (noon).
func daylight_at(t: float) -> float:
	var dawn_start: float = clock.wake_time + _t("daylight_dawn_start")
	var dawn_end: float = clock.wake_time + _t("daylight_dawn_end")
	var dusk_start: float = clock.home_time + _t("daylight_dusk_start")
	var dusk_end: float = clock.home_time + _t("daylight_dusk_end")
	if t >= dawn_end and t <= dusk_start:
		return 1.0
	if t > dusk_start and t < dusk_end:
		return 1.0 - (t - dusk_start) / (dusk_end - dusk_start)
	if t > dawn_start and t < dawn_end:
		return (t - dawn_start) / (dawn_end - dawn_start)
	return 0.0


## Dusk and dawn warmth at time of day [param t], 0..1 (prototype warmth()).
func warmth_at(t: float) -> float:
	var to_dusk: float = absf(t - (clock.home_time + _t("warmth_dusk_offset")))
	var to_dawn: float = absf(t - (clock.wake_time + _t("warmth_dawn_offset")))
	return maxf(0.0, 1.0 - minf(to_dusk, to_dawn) / _t("warmth_width"))


func _setup() -> void:
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if _tuning.is_empty():
		get_tree().quit(1)
		return
	_night_tint = _channels(_tuning["night_tint"])
	_warm_tint = _channels(_tuning["warm_tint"])
	_update(true)
	set_process(true)


func _update(force: bool) -> void:
	daylight = daylight_at(clock.time)
	warmth = warmth_at(clock.time)
	night_amount = (1.0 - daylight) * _t("night_strength")
	_apply_tint()
	var night_now: bool = daylight < _t("night_below_daylight")
	if night_now == is_night and not force:
		return
	is_night = night_now
	for building: Sprite2D in village.buildings:
		building.frame = LIT_FRAME if is_night else DAY_FRAME
	train.night = is_night
	night_changed.emit(is_night)


## Prototype tint: channel = 255 - (255 - night) x night_amount - warm x warmth, multiplied.
func _apply_tint() -> void:
	var tint_min: float = _t("tint_min")
	if night_amount <= tint_min and warmth <= tint_min:
		tint.color = Color.WHITE
		return
	var colour: Color = Color.WHITE
	colour.r = 1.0 - (1.0 - _night_tint.r) * night_amount - _warm_tint.r * warmth
	colour.g = 1.0 - (1.0 - _night_tint.g) * night_amount - _warm_tint.g * warmth
	colour.b = 1.0 - (1.0 - _night_tint.b) * night_amount - _warm_tint.b * warmth
	tint.color = colour.clamp()


func _channels(rgb: Array) -> Color:
	return Color(float(rgb[0]) / CHANNEL_MAX, float(rgb[1]) / CHANNEL_MAX, float(rgb[2]) / CHANNEL_MAX)


func _t(key: String) -> float:
	return float(_tuning[key])


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Daylight: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("Daylight: %s has no '%s'" % [path, key])
			return {}
	return data
