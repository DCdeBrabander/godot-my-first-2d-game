extends Node2D

signal level_generated

@onready var tile_map_layer = $TileMapLayer
@onready var room_light_scene = preload("res://scenes/lighting/RoomLight.tscn")

# Unit: Tile-size (of 64px)
@export var tile_size: Vector2 = Vector2(64, 64)
@export var max_level_tiles: Vector2 = Vector2(300, 300)
@export var min_room_size = Vector2(10, 10)
@export var max_room_size = Vector2(30, 30)
@export var min_corridor_width = 3
@export var max_corridor_width = 7
@export var max_room_amount: int = 10
@export var generation_fail_limit = 10

var rng

var _generated_level := {
	"bounding_box": Rect2(0, 0, 0, 0),
	"rooms": [],
	"corridors": [],
	"floor": {},
	"lights": {},
	"walls": {},
	"entry": Rect2(0, 0, 0, 0),
	"exit": Rect2(0, 0, 0, 0)
}

const TILE_SET = {
	"WALL_BLOCK": Vector2(0, 1),
	"FLOOR": Vector2(1, 1),
	
	# Single walls
	"WALL_TOP": Vector2(4, 0),
	"WALL_BOTTOM": Vector2(5, 0),
	"WALL_LEFT": Vector2(6, 0),
	"WALL_RIGHT": Vector2(7, 0),
	
	# Corners
	"WALL_CORNER_TOP_LEFT": Vector2(0, 0),
	"WALL_CORNER_TOP_RIGHT": Vector2(1, 0),
	"WALL_CORNER_BOTTOM_LEFT": Vector2(2, 0),
	"WALL_CORNER_BOTTOM_RIGHT": Vector2(3, 0),
	
	# edges
	"WALL_EDGE_TOP_LEFT": Vector2(4, 1),
	"WALL_EDGE_TOP_RIGHT": Vector2(5, 1),
	"WALL_EDGE_BOTTOM_RIGHT": Vector2(6, 1),
	"WALL_EDGE_BOTTOM_LEFT": Vector2(7, 1),
	
	# entry / exit
	"ENTRY": Vector2(2, 1),
	"EXIT": Vector2(3, 1),
}

func _ready():
	tile_map_layer.position = Vector2(0, 0)

func generate_level(_rng) -> Dictionary:
	rng = _rng
	
	# Random generate some rooms (and corridors)
	_generate_rooms(max_room_amount)
	
	# now add walls on top of fresh floor
	_generate_walls()
	
	# We have to start and end somewhere 
	_add_entry()
	_add_exit()
	
	return _generated_level

func _generate_walls():
	for tile_vector: Vector2 in _generated_level["floor"].keys():
		var surrounding_tiles = get_surrounding_tiles_at(tile_vector)
		var missing_tiles: Dictionary = {}
		
		for surrounding_tile_key in surrounding_tiles.keys():
			var surrounding_tile_vector = surrounding_tiles[surrounding_tile_key]
			
			if not _generated_level["floor"].has(surrounding_tile_vector):
				missing_tiles[surrounding_tile_key] = surrounding_tile_vector
		
		# Supports only a single simple walls, edges and corners, 
		# since we curently dont support maps that enables single tiles surrounded by 'empty' ones
		# ----
		# first check edges: 1 missing tile piece in diagonal position
		# second, check corners: have at least 3 missing connecting pieces (in all directions combined)
		# Third, check normal walls: Mostly leftovers with 1 directly adjacent tile missing
		var missing_tile_count = missing_tiles.size()
		if (missing_tile_count == 1):
			_add_edge_wall_at(tile_vector, missing_tiles)
			_add_simple_wall_at(tile_vector, missing_tiles)
			continue
		#
		_add_simple_wall_at(tile_vector, missing_tiles)
		_add_corner_wall_at(tile_vector, missing_tiles)

func _add_simple_wall_at(vector: Vector2, surrounding_vectors_without_tiles: Dictionary):
	var tile_type: String = "UNKNOWN"
	
	if (surrounding_vectors_without_tiles.has("TOP")):
		tile_type = "WALL_TOP"
	elif (surrounding_vectors_without_tiles.has("BOTTOM")):
		tile_type = "WALL_BOTTOM"
	elif (surrounding_vectors_without_tiles.has("LEFT")):
		tile_type = "WALL_LEFT"
	elif (surrounding_vectors_without_tiles.has("RIGHT")):
		tile_type = "WALL_RIGHT"
	
	if (tile_type != "UNKNOWN"):
		_generated_level["walls"][vector] = tile_type
		#_generated_level["floor"].erase(vector)
		return true

	return false
	
func _add_edge_wall_at(vector: Vector2, surrounding_vectors_without_tiles: Dictionary):
	var tile_type: String = "UNKNOWN"
	
	if (surrounding_vectors_without_tiles.has("TOP_LEFT")):
		tile_type = "WALL_EDGE_TOP_LEFT"
	elif (surrounding_vectors_without_tiles.has("TOP_RIGHT")): 
		tile_type = "WALL_EDGE_TOP_RIGHT"
	elif (surrounding_vectors_without_tiles.has("BOTTOM_LEFT")):
		tile_type = "WALL_EDGE_BOTTOM_LEFT"
	elif (surrounding_vectors_without_tiles.has("BOTTOM_RIGHT")): 
		tile_type = "WALL_EDGE_BOTTOM_RIGHT"
	
	if (tile_type != "UNKNOWN"):
		_generated_level["walls"][vector] = tile_type
		#_generated_level["floor"].erase(vector)
		return true

	return false
	
func _add_corner_wall_at(vector: Vector2, surrounding_vectors_without_tiles: Dictionary):
	var tile_type: String = "UNKNOWN"
	
	if (surrounding_vectors_without_tiles.has("LEFT") && surrounding_vectors_without_tiles.has("TOP")):
		tile_type = "WALL_CORNER_TOP_LEFT"
	elif (surrounding_vectors_without_tiles.has("TOP") && surrounding_vectors_without_tiles.has("RIGHT")):
		tile_type = "WALL_CORNER_TOP_RIGHT"
	elif (surrounding_vectors_without_tiles.has("LEFT") && surrounding_vectors_without_tiles.has("BOTTOM")):
		tile_type = "WALL_CORNER_BOTTOM_LEFT"
	elif  (surrounding_vectors_without_tiles.has("RIGHT") && surrounding_vectors_without_tiles.has("BOTTOM")):
		tile_type = "WALL_CORNER_BOTTOM_RIGHT"
	
	if (tile_type != "UNKNOWN"):
		_generated_level["walls"][vector] = tile_type
		#_generated_level["floor"].erase(vector)
		return true

	return false

func _generate_rooms(rooms_left):
	for i in range(rooms_left):
		var new_room: Rect2 = _generate_room()
		
		if _room_intersects(new_room):
			continue
			
		_add_room(new_room)
		_add_lighting(new_room)
		_generated_level["bounding_box"] = _generated_level["bounding_box"].expand(new_room.size * tile_size)
		
		if(_generated_level["rooms"].size() > 1): _generate_hallway(_generated_level["rooms"][ -2 ], new_room)

# Simply randomly generate a rectangle with a random position within the maximum size of our map
# naively try again if it intersects with one of our generated rooms
func _generate_room() -> Rect2:
	var room_size = Vector2(randi_range(min_room_size.x, max_room_size.x), randi_range(min_room_size.y, max_room_size.y))
	var room_position = Vector2(randi_range(0, max_level_tiles.x), randi_range(0, max_level_tiles.y))
	return Rect2(room_position, room_size)
	
func _generate_hallway(roomA: Rect2, roomB: Rect2):
	var centerB = snapped(roomA.get_center(), Vector2(1, 1))
	var centerA = snapped(roomB.get_center(), Vector2(1, 1))
	if rng.randi_range(0, 1) == 0:
		_add_corridor(centerB.x, centerA.x, centerB.y, Vector2.AXIS_X) # put tiles across X-axis from centerB to center A (along B.y)
		_add_corridor(centerB.y, centerA.y, centerA.x, Vector2.AXIS_Y) # link tiles via y-axis from center B to center A (along A.x)
	else:
		_add_corridor(centerB.y, centerA.y, centerB.x, Vector2.AXIS_Y)
		_add_corridor(centerB.x, centerA.x, centerA.y, Vector2.AXIS_X)

func _add_corridor(start, end, constant, axis):
	var _allowed_corridor_widths = range(min_corridor_width, max_corridor_width, 2)
	var _corridor_width: int = _allowed_corridor_widths[randi() % _allowed_corridor_widths.size()]
	var _startPoint: int = min(start, end)
	var _endPoint: int = max(start, end) + _corridor_width
	var _generated_corridor: Rect2 = Rect2(0, 0, 0, 0)
	
	for t in range(_startPoint, _endPoint):
		for _extra_width in _corridor_width:
			match axis:
				Vector2.AXIS_X: _generated_level["floor"][Vector2(t, constant + _extra_width)] = TILE_SET["FLOOR"]
				Vector2.AXIS_Y: _generated_level["floor"][Vector2(constant + _extra_width, t)] = TILE_SET["FLOOR"]
	
	# add rect2 for corridor to general list
	if(axis == Vector2.AXIS_X):
		_generated_level["corridors"].append(Rect2(_startPoint, _startPoint, _endPoint, _endPoint + _corridor_width))
	if(axis == Vector2.AXIS_Y):
		_generated_level["corridors"].append(Rect2(_startPoint, _startPoint, _corridor_width, _endPoint + _corridor_width))

func _add_room(room):
	_generated_level["rooms"].append(room)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			_generated_level["floor"][Vector2(x, y)] = TILE_SET["FLOOR"]
	
func _add_lighting(room) -> void:
	var room_center = room.get_center() * tile_size
	var _new_light = room_light_scene.instantiate()
	
	_new_light.position = room_center
	_generated_level["lights"][_new_light.position] = _new_light
	
	#add_child(_new_light)

func _add_exit():
	var random_room = get_random_room()
	if ! random_room:
		print("Sir, there is no room for an exit...?")
		return
	
	# for now naively try again
	if random_room.position == _generated_level["entry_room"].position:
		print("cannot have exit in same room as where we started, whats the fun in that? lets try again")
		_add_exit()
	
	_generated_level["exit_room"] = random_room

func _add_entry():
	var random_room = get_random_room()
	if ! random_room:
		print("Sir, there is no room for to start our adventure...?")
		return
		
	_generated_level["entry_room"] = random_room
	
func _room_intersects(new_room: Rect2) -> bool:
	if (_generated_level["rooms"].size() == 0): return false
	var exists := false
	for existing_room in _generated_level["rooms"]:
		if (new_room.intersects(existing_room, true)):
			exists = true
			break
	return exists
	
func get_level_data() -> Dictionary:
	return _generated_level

func get_level_size() -> Vector2:
	return _generated_level["bounding_box"].size

# TODO exclude specific rooms? (like entry and exit)
func get_random_room():
	if ! _generated_level["rooms"].size():
		print("unable to get random room")
		return false

	return _generated_level["rooms"][randi() % _generated_level["rooms"].size()]

# TODO exlcude entry/exit
func get_random_room_spawn() -> Vector2:
	var random_selected_room = get_random_room()
	
	if ! random_selected_room:
		return Vector2.ZERO
		
	var random_position_x = randi_range(random_selected_room.position.x + 1, random_selected_room.position.x + random_selected_room.size.x - 1)
	var random_position_y = randi_range(random_selected_room.position.y + 1, random_selected_room.position.y + random_selected_room.size.y - 1)
	
	return Vector2(random_position_x * tile_size.x, random_position_y * tile_size.y)

func get_surrounding_tiles_at(tile: Vector2) -> Dictionary:
	return {
		"LEFT": 		Vector2(tile.x - 1, 	tile.y		),	# left
		"TOP_LEFT": 	Vector2(tile.x - 1, 	tile.y - 1	),	# top left
		"TOP": 			Vector2(tile.x, 		tile.y - 1	), 	# top
		"TOP_RIGHT":	Vector2(tile.x + 1, 	tile.y - 1	),	# top right
		"RIGHT": 		Vector2(tile.x + 1, 	tile.y		), 	# right
		"BOTTOM_RIGHT": Vector2(tile.x + 1, 	tile.y + 1	),	# bottom right
		"BOTTOM": 		Vector2(tile.x, 		tile.y + 1	),	# bottom
		"BOTTOM_LEFT": 	Vector2(tile.x - 1, 	tile.y + 1	),	# bottom left
	}

func get_area_for_position(position: Vector2):
	for room: Rect2 in _generated_level["rooms"]:
		if room.has_point(position / tile_size):
			return room
			
	for corridor: Rect2 in _generated_level["corridors"]:
		if corridor.has_point(position / tile_size):
			return corridor
	
	print("no area found")
	return false

func get_tile_size() -> Vector2: 
	return tile_size
