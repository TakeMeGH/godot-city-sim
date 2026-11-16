class_name Villager
extends Node2D
## One resident of the village (story 003): a sprite in the village's y-sorted World
## that walks a path of tile points, lingers, waits and hides. Decisions (where to go,
## when) are made by [VillagerRoutines]; this node only moves, poses and holds state.
##
## The node's position is the villager's ground anchor ([method VillageScene.tile_to_world]
## of [member tile_pos]), so it depth-sorts by its feet.
##
## Facing (sprite sheet: 0 front stand, 1-3 front walk, 4 back stand, 5-7 back walk,
## 8 punch, 9 kick): moving +i walks SE = front mirrored, -i walks NW = back mirrored,
## +j walks SW = front, -j walks NE = back.

enum State { HOME, WALK, IDLE, WAIT, AWAY }

const STAND_FRAME: int = 0
const BACK_FRAME_OFFSET: int = 4
const PUNCH_FRAME: int = 8
const KICK_FRAME: int = 9
const WALK_CYCLE: Array[int] = [1, 2, 3, 2]
const TRAINING_POSES: Array[int] = [PUNCH_FRAME, STAND_FRAME, KICK_FRAME, STAND_FRAME]
const ARRIVED_EPSILON: float = 0.0001

## Display name, e.g. "Haru".
var villager_name: String = ""
## Body (base) type that behaviour keys on: "ninja", "kunoichi", "elder" or "kid". A role
## villager (story 010) has its role's base type here, so routines, poses and events treat
## it like that body.
var type: String = ""
## Name of the sprite sheet this villager wears (a look such as "ninja_look3", or a role
## sheet), from the layout's sprite table. Story 010; for display only, never for behaviour.
var look: String = ""
## Role key from the tuning [code]roles[/code] table (e.g. "ramen_cook"), or "" for an
## ordinary resident (story 010).
var role: String = ""
## Role title shown by the click label (e.g. "ramen cook"), or "" for an ordinary resident.
var role_title: String = ""
## The walkable tile in front of this villager's home door.
var home_door: Vector2i = Vector2i.ZERO
## True for the villagers who are out at night and home by day.
var night_watch: bool = false
## Current state of the routine.
var state: State = State.HOME
## What the villager is doing, as text (e.g. "training"). Read by the HUD (story 007).
var activity: String = "at home"
## Set by another system (e.g. an event, story 005) to hold this villager: while it is
## not null the routines neither count down nor pick a new activity, and the villager
## does not board the train. Clear it to null and call
## [method VillagerRoutines.next_activity] to hand the villager back.
var lock: Object = null
## Seconds left to linger, wait, or (at home) before leaving.
var timer: float = 0.0
## Position in tile coordinates (i, j as floats).
var tile_pos: Vector2 = Vector2.ZERO
## This villager's small fixed offset from a tile centre, so a crowd does not stack.
var offset_in_tile: Vector2 = Vector2.ZERO
## Tile points still to walk to, in order.
var path: Array[Vector2] = []
## Walking speed in tiles per second.
var speed: float = 0.0
## True while facing away from the camera (back frames).
var facing_back: bool = false
## True while the sprite is mirrored.
var flipped: bool = false

var _village: VillageScene
var _sprite: Sprite2D
var _on_arrive: Callable = Callable()
var _distance: float = 0.0
var _walk_frames_per_tile: float = 1.0
var _anchor_x: float = 0.0
var _width: float = 0.0
var _poses: Array[int] = []
var _pose_seconds: float = 1.0
var _pose_timer: float = 0.0


## Builds the sprite from the layout's [param sprite_info] (w, ax of sheet [param sheet], or
## of the sheet named [param villager_type] when [param sheet] is empty) and stores who this
## is. Every look and role sheet keeps its base body's frame layout and anchor (story 010).
## Call before [method VillageScene.add_entity].
func setup(village: VillageScene, sprite_info: Dictionary, display_name: String, villager_type: String,
		door: Vector2i, offset: Vector2, walk_frames_per_tile: float, sheet: String = "") -> void:
	_village = village
	villager_name = display_name
	name = display_name
	type = villager_type
	home_door = door
	offset_in_tile = offset
	_walk_frames_per_tile = walk_frames_per_tile
	_anchor_x = float(sprite_info["ax"])
	_width = float(sprite_info["w"])
	look = sheet if not sheet.is_empty() else villager_type
	_sprite = village.create_sprite(look, STAND_FRAME)
	add_child(_sprite)


## True when the sprite sheet has the punch and kick frames (the ninja layout), whatever
## look or role sheet it is.
func has_combat_poses() -> bool:
	return _sprite.hframes > KICK_FRAME


## Puts the villager at tile point [param point] at once and drops any path.
func place(point: Vector2) -> void:
	tile_pos = point
	position = _village.tile_to_world(point.x, point.y)
	path.clear()
	_on_arrive = Callable()


## Walks through [param points] (tile coordinates) at [param walk_speed] tiles per
## second, then calls [param on_arrive]. With no points it arrives at once.
func follow(points: Array[Vector2], walk_speed: float, on_arrive: Callable) -> void:
	_poses.clear()
	path = points
	speed = walk_speed
	if points.is_empty():
		state = State.IDLE
		timer = 0.0
		_on_arrive = Callable()
		on_arrive.call()
		return
	state = State.WALK
	_on_arrive = on_arrive


## Stands still for [param seconds] doing [param label]. With [param poses] the
## sprite cycles those frames, one every [param pose_seconds].
func linger(label: String, seconds: float, poses: Array[int] = [], pose_seconds: float = 1.0) -> void:
	state = State.IDLE
	activity = label
	timer = seconds
	_poses = poses.duplicate()
	_pose_seconds = pose_seconds
	_pose_timer = 0.0
	if not poses.is_empty():
		facing_back = false


## Stands still in the [code]WAIT[/code] state for [param seconds] doing [param label].
func wait(label: String, seconds: float) -> void:
	state = State.WAIT
	activity = label
	timer = seconds
	_poses.clear()


## Hides the villager (indoors or on the train) in [param hidden_state].
func disappear(hidden_state: State, label: String) -> void:
	visible = false
	state = hidden_state
	activity = label
	path.clear()
	_poses.clear()
	_on_arrive = Callable()


## Advances the walk by [param delta] seconds, calls the arrival callback when the
## path runs out, and updates the sprite frame.
func step(delta: float) -> void:
	var walking: bool = not path.is_empty()
	var budget: float = speed * delta
	while budget > 0.0 and not path.is_empty():
		var to: Vector2 = path[0] - tile_pos
		var distance: float = to.length()
		if distance > ARRIVED_EPSILON:
			if absf(to.x) > absf(to.y):
				facing_back = to.x < 0.0
				flipped = true
			else:
				facing_back = to.y < 0.0
				flipped = false
		if distance <= budget:
			tile_pos = path[0]
			path.remove_at(0)
			budget -= distance
			_distance += distance
		else:
			tile_pos += to / distance * budget
			_distance += budget
			budget = 0.0
	if walking:
		position = _village.tile_to_world(tile_pos.x, tile_pos.y)
		if path.is_empty() and state == State.WALK:
			state = State.IDLE
			timer = 0.0
			var arrive: Callable = _on_arrive
			_on_arrive = Callable()
			if arrive.is_valid():
				arrive.call()
	_update_frame(delta)


func _update_frame(delta: float) -> void:
	var base: int = BACK_FRAME_OFFSET if facing_back else STAND_FRAME
	if not _poses.is_empty():
		_pose_timer += delta
		_sprite.frame = _poses[floori(_pose_timer / _pose_seconds) % _poses.size()]
	elif not path.is_empty():
		_sprite.frame = base + WALK_CYCLE[floori(_distance * _walk_frames_per_tile) % WALK_CYCLE.size()]
	else:
		_sprite.frame = base
	# flip_h mirrors inside the sprite's rect, so move the offset to keep the anchor under the feet.
	_sprite.flip_h = flipped
	_sprite.offset.x = -(_width - _anchor_x) if flipped else -_anchor_x


## Pixels from the ground anchor up to the top of the sprite, so a label can sit above the
## head (story 007).
func height_above_feet() -> float:
	return -_sprite.get_rect().position.y if _sprite != null else 0.0
