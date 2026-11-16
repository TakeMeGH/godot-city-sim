class_name DayClock
extends Node
## The village day clock (design/game-brief.md, Features item 3; story 003).
## [member time] runs from 0 (midnight) through 0.5 (noon) back to 0, starting at
## [code]start_time[/code]; one full day takes [code]day_seconds[/code] real seconds.
## It runs on the physics step, so [code]Engine.time_scale[/code] speeds it up.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code]:
## [codeblock]
## day_seconds   real seconds for one day
## start_time    time of day at start (0..1)
## wake_time     dawn: villagers leave home from here
## home_time     dusk: villagers head home from here
## [/codeblock]
##
## Command-line user arg (after [code]--[/code]) for repeatable screenshots:
## [codeblock]
## godot --path . -- --time=0.5   # start at noon instead of start_time
## [/codeblock]

## Emitted when the clock passes [code]wake_time[/code].
signal dawn()
## Emitted when the clock passes [code]home_time[/code].
signal dusk()
## Emitted when the clock passes midnight; [member day] has already gone up.
signal new_day()

const TUNING_KEYS: Array[String] = ["day_seconds", "start_time", "wake_time", "home_time"]
const ARG_TIME: String = "--time="
const MINUTES_PER_DAY: int = 24 * 60

## Time of day, 0..1 (0 = midnight, 0.5 = noon).
var time: float = 0.0
## Day number, starting at 1.
var day: int = 1
## Time of day when villagers leave home.
var wake_time: float = 0.0
## Time of day when villagers head home.
var home_time: float = 0.0

var _day_seconds: float = 1.0


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VillageScene.TUNING_PATH))
	var tuning: Dictionary = parsed if parsed is Dictionary else {}
	for key: String in TUNING_KEYS:
		if not tuning.has(key):
			push_error("DayClock: %s has no '%s'" % [VillageScene.TUNING_PATH, key])
			get_tree().quit(1)
			return
	_day_seconds = float(tuning["day_seconds"])
	wake_time = float(tuning["wake_time"])
	home_time = float(tuning["home_time"])
	time = float(tuning["start_time"])
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with(ARG_TIME):
			continue
		var value: String = arg.trim_prefix(ARG_TIME)
		if value.is_valid_float():
			time = fposmod(value.to_float(), 1.0)
		else:
			push_error("DayClock: expected --time=<0..1>, got '%s'" % arg)


func _physics_process(delta: float) -> void:
	var before: float = time
	time += delta / _day_seconds
	if time >= 1.0:
		time -= 1.0
		day += 1
		new_day.emit()
		_emit_crossings(before, 1.0)
		before = 0.0
	_emit_crossings(before, time)


## The time of day as 24-hour clock text, e.g. [code]"06:28"[/code].
func clock_text() -> String:
	var minutes: int = floori(time * MINUTES_PER_DAY) % MINUTES_PER_DAY
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func _emit_crossings(from: float, to: float) -> void:
	if from < wake_time and to >= wake_time:
		dawn.emit()
	if from < home_time and to >= home_time:
		dusk.emit()
