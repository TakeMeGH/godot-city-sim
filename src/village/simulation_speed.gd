class_name SimulationSpeed
extends Node
## The idle controls (design/game-brief.md, Features item 7 and Controls; story 007):
## pause, simulation speed, mute, a new day, the HUD toggle, and the title screen
## that holds the village paused until the player starts the day.
##
## Speed is a multiplier on the simulation through [code]Engine.time_scale[/code]: the
## physics tick rate never changes, but every [code]_physics_process[/code] (train,
## clock, villagers, events) gets a scaled delta. Pause uses
## [code]SceneTree.paused[/code]; this node, the HUD and the title run with
## [code]PROCESS_MODE_ALWAYS[/code].
##
## Input actions are registered at start-up (only where the project's InputMap does
## not already define them, so they stay remappable):
## [codeblock]
## sim_pause      Space, P, Escape, gamepad Start   pause / carry on
## sim_speed_1/2/3  1, 2, 3, D-pad left/up/right     x1, x speed_2, x speed_3
## sim_mute       M                                 mute the Master bus
## sim_new_day    R                                 restart the day at start_time
## sim_hud        H, gamepad Back                   hide / show the HUD
## title_start    Enter, Space, gamepad A / Start   start the day from the title
## [/codeblock]
##
## Tuning keys in [code]assets/data/village_tuning.json[/code]:
## [codeblock]
## speed_2, speed_3   multipliers on keys 2 and 3 (key 1 is always x1)
## start_time         time of day a new day (R) starts at
## [/codeblock]
##
## Command-line user args (after [code]--[/code]) for repeatable screenshots:
## [codeblock]
## godot --path . -- --skip-title   # no title screen: the day starts at once
## godot --path . -- --speed=3      # start at speed level 1, 2 or 3
## godot --path . -- --paused       # start the day paused (the Paused panel shows)
## [/codeblock]

## Emitted once the title is dismissed (or skipped) and the village runs.
signal day_started()
## Emitted when the player pauses or carries on.
signal paused_changed(paused: bool)
## Emitted when the speed changes; [param multiplier] is the new time scale.
signal speed_changed(multiplier: float)
## Emitted when H hides or shows the HUD.
signal hud_visibility_changed(shown: bool)

const TUNING_KEYS: Array[String] = ["speed_2", "speed_3", "start_time"]
const ARG_SKIP_TITLE: String = "--skip-title"
const ARG_SPEED: String = "--speed="
const ARG_PAUSED: String = "--paused"
const MASTER_BUS: String = "Master"

const ACTION_PAUSE: StringName = &"sim_pause"
const ACTION_SPEED_1: StringName = &"sim_speed_1"
const ACTION_SPEED_2: StringName = &"sim_speed_2"
const ACTION_SPEED_3: StringName = &"sim_speed_3"
const ACTION_MUTE: StringName = &"sim_mute"
const ACTION_NEW_DAY: StringName = &"sim_new_day"
const ACTION_HUD: StringName = &"sim_hud"
const ACTION_START: StringName = &"title_start"

## Default keys (physical positions, like the prototype's KeyboardEvent.code).
const KEY_BINDINGS: Dictionary = {
	ACTION_PAUSE: [KEY_SPACE, KEY_P, KEY_ESCAPE],
	ACTION_SPEED_1: [KEY_1, KEY_KP_1],
	ACTION_SPEED_2: [KEY_2, KEY_KP_2],
	ACTION_SPEED_3: [KEY_3, KEY_KP_3],
	ACTION_MUTE: [KEY_M],
	ACTION_NEW_DAY: [KEY_R],
	ACTION_HUD: [KEY_H],
	ACTION_START: [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
}
## Default gamepad buttons.
const JOY_BINDINGS: Dictionary = {
	ACTION_PAUSE: [JOY_BUTTON_START],
	ACTION_SPEED_1: [JOY_BUTTON_DPAD_LEFT],
	ACTION_SPEED_2: [JOY_BUTTON_DPAD_UP],
	ACTION_SPEED_3: [JOY_BUTTON_DPAD_RIGHT],
	ACTION_HUD: [JOY_BUTTON_BACK],
	ACTION_START: [JOY_BUTTON_A, JOY_BUTTON_START],
}

## Survive the scene reload that R does: the new scene skips the title, starts at
## start_time and keeps the HUD hidden if it was.
static var _restarting: bool = false
static var _hud_hidden: bool = false

## The day clock, reset to start_time on a new day.
@export var clock: DayClock
## The village log, for "You arrive at the village" / "A new day in the village".
@export var village_log: VillageLog
## The title screen; freed once the day starts.
@export var title: TitleScreen

## True once the title is gone and the village runs.
var has_started: bool = false
## True while the player has paused (not while the title holds the village).
var is_paused: bool = false
## False while H has hidden the HUD.
var hud_visible: bool = true
## The current multiplier (1, speed_2 or speed_3).
var speed: float = 1.0
## The current speed level, 1..3.
var speed_level: int = 1

var _speeds: Array[float] = [1.0, 1.0, 1.0]
var _start_level: int = 1
var _start_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_input_actions()
	var tuning: Dictionary = load_tuning(TUNING_KEYS, "SimulationSpeed")
	if tuning.is_empty():
		get_tree().quit(1)
		return
	_speeds = [1.0, float(tuning["speed_2"]), float(tuning["speed_3"])]
	hud_visible = not _hud_hidden
	var restarted: bool = _restarting
	_restarting = false
	var skip_title: bool = restarted
	if not restarted:
		for arg: String in OS.get_cmdline_user_args():
			if arg == ARG_SKIP_TITLE:
				skip_title = true
			elif arg == ARG_PAUSED:
				_start_paused = true
			elif arg.begins_with(ARG_SPEED):
				var value: String = arg.trim_prefix(ARG_SPEED)
				if value.is_valid_int() and int(value) >= 1 and int(value) <= _speeds.size():
					_start_level = int(value)
				else:
					push_error("SimulationSpeed: expected --speed=1|2|3, got '%s'" % arg)
	else:
		# A new day starts at the start time, before the villagers place themselves
		# (they set up on VillageScene.ready, which comes after this _ready).
		clock.time = float(tuning["start_time"])
		clock.day = 1
	Engine.time_scale = 1.0
	get_tree().paused = true
	var first_line: String = "A new day in the village" if restarted else "You arrive at the village"
	if skip_title or title == null:
		if title != null:
			title.queue_free()
			title = null
		_begin_day.call_deferred(first_line)
	else:
		title.start_requested.connect(_begin_day.bind(first_line), CONNECT_ONE_SHOT)
		title.open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_MUTE):
		set_muted(not is_muted())
		get_viewport().set_input_as_handled()
		return
	if not has_started:
		return
	if event.is_action_pressed(ACTION_PAUSE):
		set_paused(not is_paused)
	elif is_paused:
		return
	elif event.is_action_pressed(ACTION_SPEED_1):
		set_speed_level(1)
	elif event.is_action_pressed(ACTION_SPEED_2):
		set_speed_level(2)
	elif event.is_action_pressed(ACTION_SPEED_3):
		set_speed_level(3)
	elif event.is_action_pressed(ACTION_HUD):
		set_hud_visible(not hud_visible)
	elif event.is_action_pressed(ACTION_NEW_DAY):
		new_day()
	else:
		return
	get_viewport().set_input_as_handled()


## Pauses or resumes the simulation (the whole scene tree except the UI).
## Example: [code]sim.set_paused(true)[/code]
func set_paused(paused: bool) -> void:
	is_paused = paused
	get_tree().paused = paused
	paused_changed.emit(paused)


## Sets speed level 1, 2 or 3 (x1, x speed_2, x speed_3) on [code]Engine.time_scale[/code].
## Example: [code]sim.set_speed_level(2)[/code]
func set_speed_level(level: int) -> void:
	speed_level = clampi(level, 1, _speeds.size())
	speed = _speeds[speed_level - 1]
	Engine.time_scale = speed
	speed_changed.emit(speed)


## Shows or hides the HUD (the selected-villager label and the Paused panel stay).
func set_hud_visible(shown: bool) -> void:
	hud_visible = shown
	hud_visibility_changed.emit(shown)


## Mutes or unmutes the Master audio bus.
func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), muted)


## True while the Master bus is muted.
func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(MASTER_BUS))


## Starts a new day: reloads the village at start_time, at x1, keeping mute and the
## HUD toggle, and logs "A new day in the village".
func new_day() -> void:
	_restarting = true
	_hud_hidden = not hud_visible
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene.call_deferred()


## Registers the default keys and buttons for every action this game uses, skipping
## actions the project's InputMap already defines. Safe to call more than once.
static func ensure_input_actions() -> void:
	for action: StringName in KEY_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEY_BINDINGS[action]:
			var key_event: InputEventKey = InputEventKey.new()
			key_event.physical_keycode = key
			InputMap.action_add_event(action, key_event)
		if JOY_BINDINGS.has(action):
			for button: JoyButton in JOY_BINDINGS[action]:
				var joy_event: InputEventJoypadButton = InputEventJoypadButton.new()
				joy_event.button_index = button
				InputMap.action_add_event(action, joy_event)


## The real (unscaled) seconds behind a scaled frame [param delta], for UI timers that
## must not speed up with the simulation.
## Example: [code]_age += SimulationSpeed.real_delta(delta)[/code]
static func real_delta(delta: float) -> float:
	return delta / Engine.time_scale if Engine.time_scale > 0.0 else delta


## Reads [code]village_tuning.json[/code] and checks it has every key in [param keys].
## Returns an empty dictionary (and logs, naming [param who]) when it does not.
static func load_tuning(keys: Array[String], who: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VillageScene.TUNING_PATH))
	if not parsed is Dictionary:
		push_error("%s: %s is missing or is not a JSON object" % [who, VillageScene.TUNING_PATH])
		return {}
	var data: Dictionary = parsed
	for key: String in keys:
		if not data.has(key):
			push_error("%s: %s has no '%s'" % [who, VillageScene.TUNING_PATH, key])
			return {}
	return data


func _begin_day(first_line: String) -> void:
	if title != null:
		title.close()
		title = null
	has_started = true
	set_speed_level(_start_level)
	_start_level = 1
	set_paused(_start_paused)
	_start_paused = false
	village_log.add_line(first_line)
	day_started.emit()
