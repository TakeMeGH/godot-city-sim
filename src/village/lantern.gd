@tool
class_name Lantern
extends PlacedSprite
## A street lantern placed in the village scene: frame 0 is unlit, frame 1 is lit. The glow
## around a lit lantern is not drawn here ([NightGlow]). In group "lantern"; [VillageScene]
## collects every lantern into [member VillageScene.lanterns] in scene order.

## The sprite a new lantern draws (a saved lantern sets its own).
const DEFAULT_SPRITE: String = "lantern"
const UNLIT_FRAME: int = 0
const LIT_FRAME: int = 1

## True while the lit frame is showing.
var is_lit: bool = false


func _init() -> void:
	add_to_group(&"lantern")
	if sprite_name.is_empty():
		sprite_name = DEFAULT_SPRITE


## Switches between the unlit and the lit frame.
## Example: [code]for lantern in village.lanterns: lantern.set_lit(true)[/code]
func set_lit(lit: bool) -> void:
	is_lit = lit
	frame = LIT_FRAME if lit else UNLIT_FRAME
