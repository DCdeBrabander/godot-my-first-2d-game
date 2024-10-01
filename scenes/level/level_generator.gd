extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

@export var tile_size: Vector2 = Vector2(64, 64)
@export var level_size: Vector2 = Vector2(100, 100)
@export var min_room_size = Vector2(10, 10)
@export var max_room_size = Vector2(30, 30)
@export var min_corridor_width = 3
@export var max_corridor_width = 5
@export var max_room_amount: int = randi_range(3, 10)
@export var generation_fail_limit = 10

var _generated_level := {}
var _generated_rooms: Array = []

var rng := RandomNumberGenerator.new()

enum TILE_TYPE {
	ROOM_FLOOR = 0,
	CORRIDOR_FLOOR = 1
}

func _ready():
	tile_map_layer.position = Vector2(0, 0)
	generate_level()
	
func generate_level():
	rng.randomize()
	tile_map_layer.clear() 
	
	_generate_rooms(max_room_amount, generation_fail_limit)
	
	# TODO: update to read tile (source id) dynamically
	for tile_vector in _generated_level.keys():
		tile_map_layer.set_cell(tile_vector, 0, Vector2(0, 0), 0)

	print(_generated_rooms.size())
	
# Needs a lot more logic later
func get_random_spawn_point():
	var random_tile = _generated_level.keys()[randi() % _generated_level.size()]
	return random_tile * tile_size

func _generate_rooms(rooms_left, max_retries):
	if (max_retries <= 0): return
		
	for i in range(rooms_left):
		var new_room = _generate_room()
		
		if _room_intersects(new_room):
			continue
			
		_add_room(new_room)
		
		if(_generated_rooms.size() > 1): _generate_hallway(_generated_rooms[ -2 ], new_room)

# Simply randomly generate a rectangle with a random position within the maximum size of our map
# naively try again if it intersects with one of our generated rooms
func _generate_room() -> Rect2:
	var room_size = Vector2(randi_range(min_room_size.x, max_room_size.x), randi_range(min_room_size.y, max_room_size.y))
	var room_position = Vector2(randf_range(0, level_size.x), randf_range(0, level_size.y))
	return Rect2(room_position, room_size)
	
func _generate_hallway(roomA: Rect2, roomB: Rect2):
	var centerB = roomA.get_center()
	var centerA = roomB.get_center()
	if rng.randi_range(0, 1) == 0:
		_add_corridor(centerB.x, centerA.x, centerB.y, Vector2.AXIS_X) # put tiles across X-axis from centerB to center A (along B.y)
		_add_corridor(centerB.y, centerA.y, centerA.x, Vector2.AXIS_Y) # link tiles via y-axis from center B to center A (along A.x)
	else:
		_add_corridor(centerB.y, centerA.y, centerB.x, Vector2.AXIS_Y)
		_add_corridor(centerB.x, centerA.x, centerA.y, Vector2.AXIS_X)

func _add_room(room):
	_generated_rooms.append(room)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			_generated_level[Vector2(x, y)] = TILE_TYPE.ROOM_FLOOR
	
func _add_corridor(start, end, constant, axis):
	var _corridor_width = randi_range(min_corridor_width, max_corridor_width)
	var _startPoint = min(start, end)
	var _endPoint = max(start, end) + 1
	
	for t in range(_startPoint, _endPoint):
		var points = []
		for _extra_width in range(1, _corridor_width):
			match axis:
				Vector2.AXIS_X: 
					points.append(Vector2(t, constant + _extra_width))
				Vector2.AXIS_Y: 
					points.append(Vector2(constant + _extra_width, t))
		for point in points:
			_generated_level[point] = TILE_TYPE.CORRIDOR_FLOOR

func _room_intersects(new_room: Rect2) -> bool:
	if (_generated_rooms.size() == 0): return false
	var exists := false
	for existing_room in _generated_rooms:
		if (new_room.intersects(existing_room, true)):
			exists = true
			break
	return exists
