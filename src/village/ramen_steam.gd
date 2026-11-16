class_name RamenSteam
extends Sprite2D
## Steam over the ramen stand's pot (design/game-brief.md, Features item 12; story 012).
##
## A child of the stand's building sprite, at the stand's sprite-table [code]steam_point[/code]
## (see [method VillageScene._add_steam]). Its frames swap every [member frame_seconds] while
## the stand shows its open (day) frame; when [Daylight] switches the stand to its closed night
## frame (noren rolled up, lantern lit), the steam hides, so the stand closes at dusk.
## [member frame_seconds] comes from the steam sprite's table entry ([code]frame_seconds[/code]).

## Seconds per steam frame (0 keeps the first frame).
var frame_seconds: float = 0.0

var _timer: float = 0.0


func _process(delta: float) -> void:
	var stand: Sprite2D = get_parent() as Sprite2D
	visible = stand == null or stand.frame == Daylight.DAY_FRAME
	if not visible or frame_seconds <= 0.0 or hframes <= 1:
		return
	_timer += delta
	if _timer >= frame_seconds:
		_timer = fmod(_timer, frame_seconds)
		frame = (frame + 1) % hframes
