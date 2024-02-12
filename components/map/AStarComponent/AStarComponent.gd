extends Node

class_name AStarComponent

const ARRIVAL_DISTANCE: float = 8.0
const DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
const DIAGONAL_DIRECTIONS: Array[Vector2] = [
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.LEFT,
	Vector2.DOWN,
	Vector2(1, 1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(-1, -1)
]

enum PAIRING_METHODS {
	CANTOR_UNSIGNED,  # positive values only
	CANTOR_SIGNED,  # both positive and negative values
	SZUDZIK_UNSIGNED,  # more efficient than cantor
	SZUDZIK_SIGNED,  # both positive and negative values
	SZUDZIK_IMPROVED,  # improved version (best option)
}

@export var navigation_tilemap: TileMap = null

@export var diagonals: bool = true
@export var current_pairing_method: PAIRING_METHODS = PAIRING_METHODS.SZUDZIK_IMPROVED

var _target_node: Node

var _astar: AStar2D = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if not _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	_astar = AStar2D.new()

	create_pathfinding_points()


func create_pathfinding_points() -> void:
	_astar.clear()

	var used_cell_positions: Array[Vector2i] = navigation_tilemap.get_used_cells(0)

	for cell_position in used_cell_positions:
		_astar.add_point(get_point(cell_position), cell_position)

	for cell_position in used_cell_positions:
		connect_cardinals(cell_position)


func connect_cardinals(point_position) -> void:
	var center: int = get_point(point_position)
	var directions: Array[Vector2] = []

	if diagonals:
		directions = DIAGONAL_DIRECTIONS
	else:
		directions = DIRECTIONS

	for direction in directions:
		var cardinal_point: int = get_point(
			point_position + navigation_tilemap.local_to_map(direction)
		)

		if cardinal_point != center and _astar.has_point(cardinal_point):
			_astar.connect_points(center, cardinal_point, true)


func get_astar_path(
	start_position: Vector2, end_position: Vector2, max_distance := -1
) -> AStarPath:
	var map_start_pos: Vector2 = navigation_tilemap.local_to_map(start_position)

	var map_end_pos: Vector2 = navigation_tilemap.local_to_map(end_position)

	if not has_point(map_start_pos):
		return null

	if not has_point(map_end_pos):
		return null

	var astar_path: PackedVector2Array = _astar.get_point_path(
		get_point(map_start_pos), get_point(map_end_pos)
	)

	astar_path = set_path_length(astar_path, max_distance)

	var out_path: AStarPath = AStarPath.new()

	for step in astar_path:
		out_path.path.append(navigation_tilemap.map_to_local(step))

	return out_path


func set_path_length(point_path: Array, max_distance: int) -> Array:
	if max_distance < 0:
		return point_path

	var new_size: int = int(min(point_path.size(), max_distance))

	point_path.resize(new_size)

	return point_path


func get_point(point_position: Vector2) -> int:
	var a: int = int(point_position.x)
	var b: int = int(point_position.y)
	match current_pairing_method:
		PAIRING_METHODS.CANTOR_UNSIGNED:
			assert(
				a >= 0 and b >= 0,
				"Board: pairing method has failed. Choose method that supports negative values."
			)
			return cantor_pair(a, b)
		PAIRING_METHODS.SZUDZIK_UNSIGNED:
			assert(
				a >= 0 and b >= 0,
				"Board: pairing method has failed. Choose method that supports negative values."
			)
			return szudzik_pair(a, b)
		PAIRING_METHODS.CANTOR_SIGNED:
			return cantor_pair_signed(a, b)
		PAIRING_METHODS.SZUDZIK_SIGNED:
			return szudzik_pair_signed(a, b)
		PAIRING_METHODS.SZUDZIK_IMPROVED:
			return szudzik_pair_improved(a, b)
	return szudzik_pair_improved(a, b)


func cantor_pair(a: int, b: int) -> int:
	var result := 0.5 * (a + b) * (a + b + 1) + b
	return int(result)


func cantor_pair_signed(a: int, b: int) -> int:
	if a >= 0:
		a = a * 2
	else:
		a = (a * -2) - 1
	if b >= 0:
		b = b * 2
	else:
		b = (b * -2) - 1
	return cantor_pair(a, b)


func szudzik_pair(a: int, b: int) -> int:
	if a >= b:
		return (a * a) + a + b
	else:
		return (b * b) + a


func szudzik_pair_signed(a: int, b: int) -> int:
	if a >= 0:
		a = a * 2
	else:
		a = (a * -2) - 1
	if b >= 0:
		b = b * 2
	else:
		b = (b * -2) - 1
	return int(szudzik_pair(a, b))


func szudzik_pair_improved(x: int, y: int) -> int:
	var a: int = 0
	var b: int = 0
	if x >= 0:
		a = x * 2
	else:
		a = (x * -2) - 1
	if y >= 0:
		b = y * 2
	else:
		b = (y * -2) - 1
	var c = szudzik_pair(a, b)
	if a >= 0 and b < 0 or b >= 0 and a < 0:
		return -c - 1
	return c


func has_point(point_position: Vector2) -> bool:
	var point_id: int = get_point(point_position)
	return _astar.has_point(point_id)


class AStarPath:
	extends RefCounted
	var path: Array[Vector2] = []

	func is_navigation_finished() -> bool:
		return path.size() <= 0

	func get_next_path_position(current_position: Vector2) -> Vector2:
		if is_navigation_finished():
			return current_position

		var next_path_position = path[0]

		if current_position.distance_to(next_path_position) < AStarComponent.ARRIVAL_DISTANCE:
			path.pop_front()

		return next_path_position
