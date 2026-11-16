class_name VillageLog
extends Node
## The village log (design/game-brief.md, Features item 5; story 005): one-line messages
## about what is happening, each stamped with the day clock's time
## ([method DayClock.clock_text]). Keeps the newest [code]log_lines[/code] lines; story
## 007 draws them from [member lines] / [signal line_added]. Every line is also printed
## to stdout as [code][log] HH:MM  text[/code], so a headless run shows it.
##
## Besides what events write through [method add_line], it logs on its own:
## [br]- "Day N begins" on [signal DayClock.new_day], "Morning. The village wakes up" on
## [signal DayClock.dawn];
## [br]- a share ([code]log_tag_chance[/code]) of [signal KidTag.tag_changed] as
## "little Pip is it!", and a share ([code]log_dash_chance[/code]) of
## [signal RooftopDash.dashed] as "A ninja dashes across the rooftops", sampled with the
## village's seeded generator ([member VillagerRoutines.rng]).
##
## Tuning keys in [code]assets/data/village_tuning.json[/code]:
## [codeblock]
## log_lines                         lines kept
## log_tag_chance, log_dash_chance   share of tag touches / rooftop dashes logged (0..1)
## [/codeblock]

## Emitted for each new line; [param text] is the full line with its time stamp,
## e.g. [code]"06:41  A messenger hawk circles over the village"[/code].
signal line_added(text: String)

const TUNING_KEYS: Array[String] = ["log_lines", "log_tag_chance", "log_dash_chance"]
const STDOUT_PREFIX: String = "[log] "

## The day clock, for time stamps and day changes.
@export var clock: DayClock
## The villagers' routines, for the seeded generator.
@export var routines: VillagerRoutines
## The kids' tag game.
@export var kid_tag: KidTag
## The rooftop dash.
@export var rooftop_dash: RooftopDash

## The kept lines, newest first, each with its time stamp.
var lines: Array[String] = []

var _max_lines: int = 1
var _tag_chance: float = 0.0
var _dash_chance: float = 0.0


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VillageScene.TUNING_PATH))
	var tuning: Dictionary = parsed if parsed is Dictionary else {}
	for key: String in TUNING_KEYS:
		if not tuning.has(key):
			push_error("VillageLog: %s has no '%s'" % [VillageScene.TUNING_PATH, key])
			get_tree().quit(1)
			return
	_max_lines = maxi(1, int(tuning["log_lines"]))
	_tag_chance = float(tuning["log_tag_chance"])
	_dash_chance = float(tuning["log_dash_chance"])
	clock.new_day.connect(func() -> void: add_line("Day %d begins" % clock.day))
	clock.dawn.connect(func() -> void: add_line("Morning. The village wakes up"))
	kid_tag.tag_changed.connect(_on_tag_changed)
	rooftop_dash.dashed.connect(_on_dashed)


## Adds [param text] as a new line stamped with the clock time, drops the oldest line
## past [code]log_lines[/code], prints it and emits [signal line_added].
## Example: [code]village_log.add_line("The train pulls into the station")[/code]
func add_line(text: String) -> void:
	var line: String = "%s  %s" % [clock.clock_text(), text]
	lines.push_front(line)
	while lines.size() > _max_lines:
		lines.pop_back()
	print(STDOUT_PREFIX + line)
	line_added.emit(line)


func _on_tag_changed(new_it_name: String) -> void:
	if routines.rng.randf() < _tag_chance:
		add_line("%s is it!" % new_it_name)


func _on_dashed() -> void:
	if routines.rng.randf() < _dash_chance:
		add_line("A ninja dashes across the rooftops")
