class_name TitleScreen
extends CanvasLayer
## The title screen (story 007): the game's name, a tagline and the controls over the
## held village. Enter, Space, a left click or gamepad A / Start asks to start the day;
## [SimulationSpeed] owns what happens next and frees this screen.
## Runs with [code]PROCESS_MODE_ALWAYS[/code] because the village is paused under it.

## Emitted when the player presses Enter, Space, A / Start or clicks.
signal start_requested()


## Shows the title.
func open() -> void:
	visible = true


## Removes the title for good.
func close() -> void:
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var start: bool = event.is_action_pressed(SimulationSpeed.ACTION_START)
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		start = start or (button.pressed and button.button_index == MOUSE_BUTTON_LEFT)
	if start:
		get_viewport().set_input_as_handled()
		start_requested.emit()
