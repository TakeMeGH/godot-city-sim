@tool
class_name Building
extends PlacedSprite
## A building placed in the village scene: a house, block, tower, shop, the station, gate,
## hospital, academy or a market stall (its [member PlacedSprite.sprite_name], or that entry's
## table [code]type[/code], is in the layout's [code]building_sprites[/code]). Frame 0 is day,
## frame 1 is night ([Daylight]). Its rooftop details are child [PlacedSprite]s saved in the scene.
##
## The building carries its own doors: [member door_tiles] are the walkable tiles villagers enter
## it from, [member door_kind] says who uses them ([VillagerRoutines]: "home", "shop", "market",
## "hospital"; also "station", "academy"). [VillageScene] collects them into
## [member VillageScene.doors] at startup and checks each is reachable. In group "building".

## Who uses the doors ("" = the building has no door, like the gate or the ramen stand).
@export var door_kind: String = ""
## The walkable tiles (i, j) in front of the doors (the station has three).
@export var door_tiles: Array[Vector2i] = []


func _init() -> void:
	add_to_group(&"building")
