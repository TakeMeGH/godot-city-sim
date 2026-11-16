class_name Hud
extends CanvasLayer
## The HUD (design/game-brief.md, Features item 7; story 007), on CanvasLayer 10 above the
## night glow (layer 1) and untouched by the daylight CanvasModulate: day, time and part of
## the day, the speed, the next-train countdown, the newest log lines (fading after
## [code]log_seconds[/code] real seconds), the on-screen controls and the Paused panel.
## Display only: it reads [DayClock], [Train], [VillageLog] and [SimulationSpeed] and never
## changes them. Text is Control nodes styled by [code]hud_theme.tres[/code], drawn in the
## 480x270 pixel space and scaled up by a whole number.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code]:
## [codeblock]
## log_lines          log lines shown
## log_seconds        real seconds a line stays
## log_fade_seconds   real seconds it takes to fade out at the end
## parts_of_day       [[until_time, "Name"], ...] in time order
## hud_margin         px between the HUD and the screen edge / the villager label
## [/codeblock]

const TUNING_KEYS: Array[String] = ["log_lines", "log_seconds", "log_fade_seconds", "parts_of_day", "hud_margin"]
const VARIATION_DIM: StringName = &"HudDim"
const VARIATION_GOLD: StringName = &"HudGold"

## The village, for the selected-villager label.
@export var village: VillageScene
## Pause, speed and HUD toggle state.
@export var sim: SimulationSpeed
## The day clock: day, time and part of the day.
@export var clock: DayClock
## The village log, shown as its newest lines.
@export var village_log: VillageLog
## The train, for the next-train countdown.
@export var train: Train
## The villagers, for the selected-villager label.
@export var routines: VillagerRoutines
## The kids, for the selected-villager label.
@export var kid_tag: KidTag

var _log_seconds: float = 9.0
var _fade_seconds: float = 1.0
var _margin: float = 4.0
var _parts: Array = []
## Shown log lines, newest first: {"text": String, "age": float}.
var _entries: Array[Dictionary] = []
## Log rows, bottom (newest) first.
var _rows: Array[PanelContainer] = []
var _row_labels: Array[Label] = []

@onready var _root: Control = $Root
@onready var _top: Control = $Root/Top
@onready var _clock_label: Label = $Root/Top/StatusPanel/Row/Clock
@onready var _speed_label: Label = $Root/Top/StatusPanel/Row/Speed
@onready var _train_label: Label = $Root/Top/TrainPanel/Train
@onready var _bottom: HBoxContainer = $Root/Bottom
@onready var _log_box: VBoxContainer = $Root/Bottom/Log
@onready var _controls: Control = $Root/Bottom/Controls
@onready var _pause_panel: Control = $PausePanel
@onready var _pause_box: Control = $PausePanel/Panel
@onready var _villager_label: VillagerLabel = $VillagerLabel


func _ready() -> void:
	var tuning: Dictionary = SimulationSpeed.load_tuning(TUNING_KEYS, "Hud")
	if tuning.is_empty():
		get_tree().quit(1)
		return
	_log_seconds = float(tuning["log_seconds"])
	_fade_seconds = maxf(0.01, float(tuning["log_fade_seconds"]))
	_margin = float(tuning["hud_margin"])
	_parts = tuning["parts_of_day"]
	for k: int in maxi(1, int(tuning["log_lines"])):
		var row: PanelContainer = PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.visible = false
		var label: Label = Label.new()
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(label)
		_log_box.add_child(row)
		_rows.push_front(row)
		_row_labels.push_front(label)
	for line: String in village_log.lines:
		if _entries.size() < _rows.size():
			_entries.append({"text": line, "age": 0.0})
	village_log.line_added.connect(_on_line_added)
	_villager_label.setup(village, routines, kid_tag)


func _process(delta: float) -> void:
	if not get_tree().paused:
		var real: float = SimulationSpeed.real_delta(delta)
		for k: int in range(_entries.size() - 1, -1, -1):
			_entries[k]["age"] = float(_entries[k]["age"]) + real
			if float(_entries[k]["age"]) >= _log_seconds:
				_entries.remove_at(k)
	_root.visible = sim.has_started and sim.hud_visible
	_pause_panel.visible = sim.is_paused
	if _root.visible:
		_update_status()
		_update_log()
	_update_label_limits()


## The name of the part of the day at [param t] (0..1), e.g. "Morning", from parts_of_day.
## Example: [code]hud.part_of_day(0.5)[/code] is "Midday".
func part_of_day(t: float) -> String:
	for part: Array in _parts:
		if t < float(part[0]):
			return String(part[1])
	return "" if _parts.is_empty() else String(_parts[-1][1])


func _update_status() -> void:
	_clock_label.text = tr("Day %d  %s  %s") % [clock.day, clock.clock_text(), tr(part_of_day(clock.time))]
	_speed_label.text = "x%d" % roundi(sim.speed)
	_speed_label.theme_type_variation = VARIATION_GOLD if sim.speed > 1.0 else VARIATION_DIM
	match train.get_state():
		Train.State.STOPPED:
			_train_label.text = tr("Train at the station")
		Train.State.ARRIVING:
			_train_label.text = tr("Train arriving")
		Train.State.LEAVING:
			_train_label.text = tr("Train departing")
		_:
			_train_label.text = tr("Next train in %ds") % ceili(train.seconds_to_next_train())


func _update_log() -> void:
	var row_margin: float = _rows[0].get_theme_stylebox("panel").get_minimum_size().x
	var max_width: float = _bottom.size.x - _controls.size.x - float(_bottom.get_theme_constant("separation")) - row_margin
	for k: int in _rows.size():
		var row: PanelContainer = _rows[k]
		if k >= _entries.size():
			row.visible = false
			continue
		var label: Label = _row_labels[k]
		var text: String = _entries[k]["text"]
		label.text = text
		var font: Font = label.get_theme_font("font")
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		label.custom_minimum_size.x = ceilf(clampf(width, 0.0, maxf(0.0, max_width)))
		row.visible = true
		row.modulate.a = clampf((_log_seconds - float(_entries[k]["age"])) / _fade_seconds, 0.0, 1.0)


func _update_label_limits() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var top: float = _margin
	var bottom: float = view.y - _margin
	if _root.visible:
		top = _top.get_global_rect().end.y + _margin
		bottom = _bottom.get_global_rect().position.y - _margin
	var blocked: Rect2 = _pause_box.get_global_rect() if _pause_panel.visible else Rect2()
	_villager_label.set_limits(top, bottom, blocked)


func _on_line_added(text: String) -> void:
	_entries.push_front({"text": text, "age": 0.0})
	while _entries.size() > _rows.size():
		_entries.pop_back()
