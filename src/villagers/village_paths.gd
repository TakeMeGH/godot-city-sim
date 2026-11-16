class_name VillagePaths
extends RefCounted
## Walkable tiles of the village map and shortest paths between them (story 003).
## Paths step between edge-neighbouring tiles only (no diagonals), so a walker never
## cuts a building corner.
##
## Example:
## [codeblock]
## var paths: VillagePaths = VillagePaths.new(layout["map"], layout["tile_legend"], ["dirt", "cobble"])
## var steps: Array[Vector2i] = paths.find_path(Vector2i(0, 3), Vector2i(4, 7))
## [/codeblock]

## Every walkable tile, row by row.
var walkable_tiles: Array[Vector2i] = []

var _grid: AStarGrid2D = AStarGrid2D.new()
## Tile name -> Array[Vector2i] of the walkable tiles with that name.
var _tiles_by_name: Dictionary = {}


## Builds the grid from the layout's [param map] rows and [param legend]
## (map char -> tile name). Tiles whose name is in [param walk_tile_names] are walkable.
func _init(map: Array, legend: Dictionary, walk_tile_names: Array) -> void:
	var first_row: String = map[0]
	_grid.region = Rect2i(0, 0, first_row.length(), map.size())
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.update()
	for tile_name: Variant in walk_tile_names:
		var list: Array[Vector2i] = []
		_tiles_by_name[tile_name] = list
	for j: int in map.size():
		var row: String = map[j]
		for i: int in row.length():
			var tile: Vector2i = Vector2i(i, j)
			var tile_name: String = legend[row[i]]
			if _tiles_by_name.has(tile_name):
				walkable_tiles.append(tile)
				var list: Array[Vector2i] = _tiles_by_name[tile_name]
				list.append(tile)
			else:
				_grid.set_point_solid(tile, true)


## True when [param tile] is on the map and walkable.
func is_walkable(tile: Vector2i) -> bool:
	return _grid.is_in_boundsv(tile) and not _grid.is_point_solid(tile)


## The walkable tiles called [param tile_name] in the legend (e.g. "cobble").
func tiles_of(tile_name: String) -> Array[Vector2i]:
	return _tiles_by_name[tile_name]


## The tiles to step through from [param from] to [param to], without [param from]
## and ending with [param to]. Empty when they are the same tile or no path exists.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_walkable(from) or not is_walkable(to):
		return []
	var steps: Array[Vector2i] = _grid.get_id_path(from, to)
	if not steps.is_empty():
		steps.remove_at(0)
	return steps
