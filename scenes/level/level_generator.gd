extends Node2D

signal seed_update

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var room_light_scene = preload("res://scenes/lighting/RoomLight.tscn")

@export var tile_size: Vector2 = Vector2(64, 64)
@export var level_size: Vector2 = Vector2(500, 500)
@export var min_room_size = Vector2(10, 10)
@export var max_room_size = Vector2(30, 30)
@export var min_corridor_width = 3
@export var max_corridor_width = 7
@export var max_room_amount: int = 30
@export var generation_fail_limit = 10

var _generated_level := {
	"floor": {},
	"rooms": [],
	"lights": {},
	"walls": {}
}

var rng: RandomNumberGenerator

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
}

func _ready():
	tile_map_layer.position = Vector2(0, 0)
	rng = RandomNumberGenerator.new()
	generate_level()

func generate_dark_color():
	return Color(randf_range(0.0, 0.2), randf_range(0.0, 0.2), randf_range(0.0, 0.2))
	
func generate_level():
	rng.randomize()
	seed_update.emit(rng.seed)
	tile_map_layer.clear()
	
	set_background()

	# Random generate some rooms
	_generate_rooms(max_room_amount)
	
	# Lay floor tiles for all generated rooms (and corridors)
	_generate_floor_tiles()
	
	# now add walls on top of fresh floor
	_generate_walls()

func set_background():
	RenderingServer.set_default_clear_color(generate_dark_color())

func get_surrounding_tiles_at(tile: Vector2) -> Dictionary:
	var x_snapped = snapped(tile.x, 1)
	var y_snapped = snapped(tile.y, 1)
	
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

func _generate_walls():
	for tile_vector: Vector2 in _generated_level["floor"].keys():
		var surrounding_tiles = get_surrounding_tiles_at(tile_vector)
		var missing_tiles: Dictionary = {}
		
		for surrounding_tile_key in surrounding_tiles.keys():
			var surrounding_tile_vector = surrounding_tiles[surrounding_tile_key]
			if (tile_map_layer.get_cell_source_id(surrounding_tile_vector) == -1):
				missing_tiles[surrounding_tile_key] = surrounding_tile_vector
				
		# first check edges: 1 missing tile piece in diagonal position
		# second, check corners: have 3 missing pieces in both directions
		# Third, check normal walls: Leftovers with 1 directly adjacent tile missing
		var missing_tile_count = missing_tiles.size()
		if (missing_tile_count == 1):
			_add_edge_wall_at(tile_vector, missing_tiles)
			_add_simple_wall_at(tile_vector, missing_tiles)
			continue
		
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
		_generated_level["floor"].erase(vector)
		_set_tile_at(vector, TILE_SET[tile_type])
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
		_generated_level["floor"].erase(vector)
		_set_tile_at(vector, TILE_SET[tile_type])
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
		_generated_level["floor"].erase(vector)
		_set_tile_at(vector, TILE_SET[tile_type])
		return true

	return false
		
func _generate_floor_tiles():
	for tile_vector: Vector2 in _generated_level["floor"].keys():
		_set_tile_at(tile_vector, _generated_level["floor"][tile_vector])

func get_random_spawn_point() -> Vector2:
	var random_selected_room: Rect2 = _generated_level["rooms"][randi() % _generated_level["rooms"].size()]
	
	var random_position_x = randi_range(random_selected_room.position.x + 1, random_selected_room.position.x + random_selected_room.size.x - 1)
	var random_position_y = randi_range(random_selected_room.position.y + 1, random_selected_room.position.y + random_selected_room.size.y - 1)
	
	return Vector2(random_position_x, random_position_y) * tile_size

func _generate_rooms(rooms_left):
	for i in range(rooms_left):
		var new_room: Rect2 = _generate_room()
		
		if _room_intersects(new_room):
			continue
			
		_add_room(new_room)
		_add_lighting(new_room)
		
		if(_generated_level["rooms"].size() > 1): _generate_hallway(_generated_level["rooms"][ -2 ], new_room)

# Simply randomly generate a rectangle with a random position within the maximum size of our map
# naively try again if it intersects with one of our generated rooms
func _generate_room() -> Rect2:
	var room_size = Vector2(randi_range(min_room_size.x, max_room_size.x), randi_range(min_room_size.y, max_room_size.y))
	var room_position = Vector2(randi_range(0, level_size.x), randi_range(0, level_size.y))
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

func _add_room(room):
	_generated_level["rooms"].append(room)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			_generated_level["floor"][Vector2(x, y)] = TILE_SET["FLOOR"]
	
func _add_corridor(start, end, constant, axis):
	var _allowed_corridor_widths = range(min_corridor_width, max_corridor_width, 2)
	var _corridor_width: int = _allowed_corridor_widths[randi() % _allowed_corridor_widths.size()]
	var _startPoint: int = min(start, end)
	var _endPoint: int = max(start, end) + _corridor_width
	
	for t in range(_startPoint, _endPoint):
		for _extra_width in _corridor_width:
			match axis:
				Vector2.AXIS_X: _generated_level["floor"][Vector2(t, constant + _extra_width)] = TILE_SET["FLOOR"]
				Vector2.AXIS_Y: _generated_level["floor"][Vector2(constant + _extra_width, t)] = TILE_SET["FLOOR"]

func _room_intersects(new_room: Rect2) -> bool:
	if (_generated_level["rooms"].size() == 0): return false
	var exists := false
	for existing_room in _generated_level["rooms"]:
		if (new_room.intersects(existing_room, true)):
			exists = true
			break
	return exists
	
func _set_tile_at(vector: Vector2, tile_atlas_coor: Vector2):
	tile_map_layer.set_cell(vector, 0, tile_atlas_coor, 0)

func _add_lighting(room):
	var room_center = room.get_center() * tile_size
	var _new_light = room_light_scene.instantiate()
	
	_new_light.position = room_center
	add_child(_new_light)

func get_current_seed():
	return rng.get_seed()
