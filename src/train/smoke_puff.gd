class_name SmokePuff
extends Node2D
## One puff of locomotive smoke (story 002). It drifts up and to the left, steps
## through the smoke frames as it ages, fades out, and frees itself after
## [code]smoke_life[/code] seconds. Drawn above the y-sorted world.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code]:
## [code]smoke_drift_x[/code], [code]smoke_drift_y[/code] (px per second),
## [code]smoke_life[/code] (s), [code]smoke_frame_seconds[/code] (s per frame),
## [code]smoke_alpha[/code] (start opacity), [code]smoke_fade_seconds[/code]
## (seconds for the opacity to fall by a full 1.0, as in the prototype).
##
## Example (what [Train] does):
## [codeblock]
## var puff: SmokePuff = SmokePuff.new(village.create_sprite("smoke", 0), tuning)
## puff.position = chimney_position
## village.add_entity(puff)
## [/codeblock]

## Above every z 0 sprite in the world, so the smoke draws over the train and roofs.
const DRAW_ABOVE_Z: int = 1

var _sprite: Sprite2D
var _drift: Vector2
var _life: float
var _frame_seconds: float
var _alpha: float
var _fade_seconds: float
var _age: float = 0.0


## [param sprite] is a smoke sprite from [method VillageScene.create_sprite];
## [param tuning] is the parsed village tuning file.
func _init(sprite: Sprite2D, tuning: Dictionary) -> void:
	_sprite = sprite
	_drift = Vector2(float(tuning["smoke_drift_x"]), float(tuning["smoke_drift_y"]))
	_life = float(tuning["smoke_life"])
	_frame_seconds = float(tuning["smoke_frame_seconds"])
	_alpha = float(tuning["smoke_alpha"])
	_fade_seconds = float(tuning["smoke_fade_seconds"])
	z_index = DRAW_ABOVE_Z
	modulate.a = _alpha
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
		return
	position += _drift * delta
	_sprite.frame = mini(_sprite.hframes - 1, floori(_age / _frame_seconds))
	modulate.a = maxf(0.0, _alpha - _age / _fade_seconds)
