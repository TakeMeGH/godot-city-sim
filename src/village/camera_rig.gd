class_name CameraRig
extends Camera2D
## The village camera: pans by left-mouse drag or arrow keys, drifts slowly over
## the village after a pause, and stays inside the range set in the tuning file.
##
## All numbers come from [code]assets/data/village_tuning.json[/code] through
## [method setup]. The position is rounded to whole pixels before it reaches the
## engine, so panning never shimmers at the native 480x270 resolution.
##
## Command-line user args (after the [code]--[/code] separator) fix the camera for
## repeatable screenshots:
## [codeblock]
## godot --path . -- --cam=0,192      # world position, clamped to the range; no drift, no input
## godot --path . -- --freeze-camera  # stay at the start position
## [/codeblock]

const ARG_CAM: String = "--cam="
const ARG_FREEZE: String = "--freeze-camera"

var _tuning: Dictionary = {}
var _centre: Vector2 = Vector2.ZERO
var _pos: Vector2 = Vector2.ZERO
var _idle: float = 0.0
var _time: float = 0.0
var _frozen: bool = false
var _drag_delta: Vector2 = Vector2.ZERO
var _dragging: bool = false


## Gives the rig its tuning values and the village centre in world pixels, then
## places the camera at its start position (or the [code]--cam[/code] position).
## Example: [code]rig.setup(tuning, village.tile_to_world(6, 6))[/code]
func setup(tuning: Dictionary, centre: Vector2) -> void:
	_tuning = tuning
	_centre = centre
	_pos = centre + Vector2(0.0, float(tuning["start_offset_y"]))
	for arg: String in OS.get_cmdline_user_args():
		if arg == ARG_FREEZE:
			_frozen = true
		elif arg.begins_with(ARG_CAM):
			var parts: PackedStringArray = arg.trim_prefix(ARG_CAM).split(",")
			if parts.size() == 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
				_pos = Vector2(parts[0].to_float(), parts[1].to_float())
				_frozen = true
			else:
				push_error("CameraRig: expected --cam=x,y, got '%s'" % arg)
	_pos = _clamp_to_range(_pos)
	position = _pos.round()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = button.pressed
	elif event is InputEventMouseMotion and _dragging:
		var motion: InputEventMouseMotion = event
		_drag_delta += motion.relative


func _process(delta: float) -> void:
	# Camera motion is the player's, not the simulation's: undo the speed multiplier
	# (Engine.time_scale, story 007) so panning and drift keep their real-time pace.
	if Engine.time_scale > 0.0:
		delta /= Engine.time_scale
	if _frozen:
		_drag_delta = Vector2.ZERO
		return
	_time += delta
	var manual: bool = false
	var step: float = float(_tuning["pan_speed"]) * delta
	if Input.is_key_pressed(KEY_LEFT):
		_pos.x -= step
		manual = true
	if Input.is_key_pressed(KEY_RIGHT):
		_pos.x += step
		manual = true
	if Input.is_key_pressed(KEY_UP):
		_pos.y -= step
		manual = true
	if Input.is_key_pressed(KEY_DOWN):
		_pos.y += step
		manual = true
	if _drag_delta != Vector2.ZERO:
		_pos -= _drag_delta
		_drag_delta = Vector2.ZERO
		manual = true
	_idle = 0.0 if manual else _idle + delta
	if _idle > float(_tuning["drift_after"]):
		var target: Vector2 = Vector2(
			_centre.x + float(_tuning["drift_x"]) * sin(_time * float(_tuning["drift_rate_x"])),
			_centre.y + float(_tuning["drift_centre_offset_y"])
				+ float(_tuning["drift_y"]) * sin(_time * float(_tuning["drift_rate_y"]) + float(_tuning["drift_phase_y"])))
		_pos = _pos.lerp(target, minf(1.0, delta * float(_tuning["drift_ease"])))
	_pos = _clamp_to_range(_pos)
	position = _pos.round()


func _clamp_to_range(p: Vector2) -> Vector2:
	var range_x: float = float(_tuning["cam_range_x"])
	var range_y: float = float(_tuning["cam_range_y"])
	var up_extra: float = float(_tuning["cam_range_up_extra"])
	return Vector2(
		clampf(p.x, _centre.x - range_x, _centre.x + range_x),
		clampf(p.y, _centre.y - range_y - up_extra, _centre.y + range_y))
