class_name VillagerLabel
extends PanelContainer
## The selected-villager label (story 007). A left click that is not a drag (the pointer
## moves less than [code]click_drag_px[/code] while held) selects the visible villager or
## kid nearest the click within [code]select_radius[/code], or clears the selection. The
## label shows "Name: activity" (or "Name, role title: activity" for a role villager, story
## 010), follows them above their head, keeps clear of the HUD
## panels and the Paused panel, and clears after [code]select_seconds[/code] real seconds
## (the timer stops while paused). Display only: it never changes a villager. The camera
## rig reads the same mouse events for dragging; neither consumes them.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code]:
## [codeblock]
## select_seconds    real seconds the label stays
## select_radius     px from the click a villager may be
## select_offset_y   px above the feet the distance is measured from
## select_squash_y   weight of the vertical distance
## click_drag_px     pointer travel (px) above which a press is a drag, not a click
## label_head_gap    px between the head and the label
## hud_margin        px from the screen edge
## [/codeblock]
##
## Command-line user arg (after [code]--[/code]) for repeatable screenshots:
## [codeblock]
## godot --path . -- --select-nearest=40,180   # select whoever is nearest this world point; no time-out
## [/codeblock]

const TUNING_KEYS: Array[String] = [
	"select_seconds", "select_radius", "select_offset_y", "select_squash_y", "click_drag_px",
	"label_head_gap", "hud_margin",
]
const ARG_SELECT: String = "--select-nearest="

## The selected villager or kid, or null.
var selected: Villager = null

var _routines: VillagerRoutines
var _kid_tag: KidTag
var _tuning: Dictionary = {}
var _timer: float = 0.0
var _hold: bool = false
var _pressing: bool = false
var _moved: float = 0.0
var _top_limit: float = 0.0
var _bottom_limit: float = 270.0
var _blocked: Rect2 = Rect2()

@onready var _text: Label = $Text


## Gives the label the villagers and kids to pick from, and applies
## [code]--select-nearest[/code] once the village has set up.
func setup(village: VillageScene, routines: VillagerRoutines, kid_tag: KidTag) -> void:
	_routines = routines
	_kid_tag = kid_tag
	_tuning = SimulationSpeed.load_tuning(TUNING_KEYS, "VillagerLabel")
	if _tuning.is_empty():
		get_tree().quit(1)
		return
	village.ready.connect(_apply_select_arg, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


## Where the label may go: between [param top] and [param bottom] (screen px), and not over
## [param blocked] (an empty rect blocks nothing). The HUD calls this every frame.
func set_limits(top: float, bottom: float, blocked: Rect2) -> void:
	_top_limit = top
	_bottom_limit = bottom
	_blocked = blocked


## Selects the visible villager or kid nearest world point [param world_point] within
## [param max_distance] px, or clears the selection when nobody is that close.
## Returns who was selected.
## Example: [code]label.select_nearest(Vector2(40, 180), INF)[/code]
func select_nearest(world_point: Vector2, max_distance: float) -> Villager:
	var best: Villager = null
	var best_distance: float = max_distance
	var offset_y: float = float(_tuning["select_offset_y"])
	var squash: float = float(_tuning["select_squash_y"])
	for villager: Villager in _candidates():
		if not villager.visible:
			continue
		var feet: Vector2 = villager.global_position
		var distance: float = Vector2(world_point.x - feet.x, (world_point.y - (feet.y - offset_y)) * squash).length()
		if distance < best_distance:
			best_distance = distance
			best = villager
	selected = best
	_timer = float(_tuning["select_seconds"]) if best != null else 0.0
	_hold = false
	return best


func _unhandled_input(event: InputEvent) -> void:
	if _tuning.is_empty() or get_tree().paused:
		_pressing = false
		return
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			_pressing = true
			_moved = 0.0
		elif _pressing:
			_pressing = false
			if _moved < float(_tuning["click_drag_px"]):
				var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * button.position
				select_nearest(world, float(_tuning["select_radius"]))
	elif event is InputEventMouseMotion and _pressing:
		var motion: InputEventMouseMotion = event
		_moved += absf(motion.relative.x) + absf(motion.relative.y)


func _process(delta: float) -> void:
	if _tuning.is_empty():
		return
	if is_instance_valid(selected) and not _hold and not get_tree().paused:
		_timer -= SimulationSpeed.real_delta(delta)
		if _timer <= 0.0:
			selected = null
	if not is_instance_valid(selected) or not selected.visible:
		visible = false
		return
	if selected.role_title.is_empty():
		_text.text = tr("%s: %s") % [selected.villager_name, selected.activity]
	else:
		_text.text = tr("%s, %s: %s") % [selected.villager_name, selected.role_title, selected.activity]
	visible = true
	var box: Vector2 = get_combined_minimum_size()
	size = box
	var view: Vector2 = get_viewport_rect().size
	var margin: float = float(_tuning["hud_margin"])
	var gap: float = float(_tuning["label_head_gap"])
	var anchor: Vector2 = get_viewport().get_canvas_transform() * selected.global_position
	var x: float = clampf(anchor.x - box.x * 0.5, margin, view.x - box.x - margin)
	var y: float = anchor.y - selected.height_above_feet() - gap - box.y
	y = maxf(_top_limit, minf(y, _bottom_limit - box.y))
	if _blocked.has_area() and Rect2(Vector2(x, y), box).intersects(_blocked):
		y = _blocked.position.y - box.y - gap
		if y < _top_limit:
			y = _blocked.end.y + gap
	position = Vector2(x, y).round()


func _candidates() -> Array[Villager]:
	var all: Array[Villager] = []
	if _routines != null:
		all.append_array(_routines.villagers)
	if _kid_tag != null:
		all.append_array(_kid_tag.kids)
	return all


func _apply_select_arg() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with(ARG_SELECT):
			continue
		var parts: PackedStringArray = arg.trim_prefix(ARG_SELECT).split(",")
		if parts.size() == 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
			select_nearest(Vector2(parts[0].to_float(), parts[1].to_float()), INF)
			_hold = selected != null
		else:
			push_error("VillagerLabel: expected --select-nearest=x,y, got '%s'" % arg)
