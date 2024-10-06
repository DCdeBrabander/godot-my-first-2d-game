extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var room_light_scene = preload("res://scenes/lighting/RoomLight.tscn")

@export var tile_size: Vector2 = Vector2(64, 64)
@export var level_size: Vector2 = Vector2(500, 500)
@export var min_room_size = Vector2(10, 10)
@export var max_room_size = Vector2(30, 30)
@export var min_corridor_width = 3
@export var max_corridor_width = 7
@export var max_room_amount: int = 20
@export var generation_fail_limit = 10

var _generated_level := {}
var _generated_rooms: Array = []
var _generated_room_lighting: Array = []
var _generated_walls := {}

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
	
func generate_level():
	rng.randomize()
	tile_map_layer.clear()

	# Random generate some rooms
	_generate_rooms(max_room_amount, generation_fail_limit)
	
	# Lay floor tiles for all generated rooms (and corridors)
	_generate_floor_tiles()
	
	tile_map_layer.update_internals()
	
	# now add walls on top of fresh floor
	_generate_walls()
	
	

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
	
	for tile_vector: Vector2 in _generated_level.keys():
		var surrounding_tiles = get_surrounding_tiles_at(tile_vector)
		var missing_tiles: Dictionary = {}
		
		for surrounding_tile_key in surrounding_tiles.keys():
			var surrounding_tile_vector = surrounding_tiles[surrounding_tile_key]
			if (tile_map_layer.get_cell_source_id(surrounding_tile_vector) == -1 && !_generated_walls.has(surrounding_tile_key)):
				missing_tiles[surrounding_tile_key] = surrounding_tile_vector
				
		# first check edges, 1 missing tile piece in diagonal position
		# then check corners, have 3 missing pieces in both directions
		# then check normal walls, always(?) have 3 missing pieces in single 'side' 
		var missing_tile_count = missing_tiles.size()
		if (missing_tile_count == 1):
			if (missing_tiles.has("TOP_LEFT")):
				_generated_walls[tile_vector] = TILE_SET["WALL_EDGE_TOP_LEFT"]
				_set_tile_at(tile_vector, TILE_SET["WALL_EDGE_TOP_LEFT"])
			elif (missing_tiles.has("TOP_RIGHT")): 
				_generated_walls[tile_vector] = TILE_SET["WALL_EDGE_TOP_RIGHT"]
				_set_tile_at(tile_vector, TILE_SET["WALL_EDGE_TOP_RIGHT"])
			elif (missing_tiles.has("BOTTOM_LEFT")):
				_generated_walls[tile_vector] = TILE_SET["WALL_EDGE_BOTTOM_LEFT"]
				_set_tile_at(tile_vector, TILE_SET["WALL_EDGE_BOTTOM_LEFT"])
			elif (missing_tiles.has("BOTTOM_RIGHT")): 
				_generated_walls[tile_vector] = TILE_SET["WALL_EDGE_BOTTOM_RIGHT"]
				_set_tile_at(tile_vector, TILE_SET["WALL_EDGE_BOTTOM_RIGHT"])
			# SINGLE WALLS
			if (missing_tiles.has("TOP")):
				_generated_walls[tile_vector] = TILE_SET["WALL_TOP"]
				_set_tile_at(tile_vector, TILE_SET["WALL_TOP"])
			elif (missing_tiles.has("BOTTOM")):
				_generated_walls[tile_vector] = TILE_SET["WALL_BOTTOM"]
				_set_tile_at(tile_vector, TILE_SET["WALL_BOTTOM"])
			elif (missing_tiles.has("LEFT")):
				_generated_walls[tile_vector] = TILE_SET["WALL_LEFT"]
				_set_tile_at(tile_vector, TILE_SET["WALL_LEFT"])
			elif (missing_tiles.has("RIGHT")):
				_generated_walls[tile_vector] = TILE_SET["WALL_RIGHT"]
				_set_tile_at(tile_vector, TILE_SET["WALL_RIGHT"])
			continue
		
		if (missing_tiles.has("LEFT") && missing_tiles.has("TOP")):
			_generated_walls[tile_vector] = TILE_SET["WALL_CORNER_TOP_LEFT"]
			_set_tile_at(tile_vector, TILE_SET["WALL_CORNER_TOP_LEFT"])

			continue
		elif (missing_tiles.has("TOP") && missing_tiles.has("RIGHT")):
			_generated_walls[tile_vector] = TILE_SET["WALL_CORNER_TOP_RIGHT"]
			_set_tile_at(tile_vector, TILE_SET["WALL_CORNER_TOP_RIGHT"])

			continue
		elif (missing_tiles.has("LEFT") && missing_tiles.has("BOTTOM")):
			_generated_walls[tile_vector] = TILE_SET["WALL_CORNER_BOTTOM_LEFT"]
			_set_tile_at(tile_vector, TILE_SET["WALL_CORNER_BOTTOM_LEFT"])

			continue
		elif  (missing_tiles.has("RIGHT") && missing_tiles.has("BOTTOM")):
			_generated_walls[tile_vector] = TILE_SET["WALL_CORNER_BOTTOM_RIGHT"]
			_set_tile_at(tile_vector, TILE_SET["WALL_CORNER_BOTTOM_RIGHT"])

			continue	
			
		# SINGLE WALLS
		if (missing_tiles.has("TOP")):
			_generated_walls[tile_vector] = TILE_SET["WALL_TOP"]
			_set_tile_at(tile_vector, TILE_SET["WALL_TOP"])
			continue
		elif (missing_tiles.has("BOTTOM")):
			_generated_walls[tile_vector] = TILE_SET["WALL_BOTTOM"]
			_set_tile_at(tile_vector, TILE_SET["WALL_BOTTOM"])
			continue
		elif (missing_tiles.has("LEFT")):
			_generated_walls[tile_vector] = TILE_SET["WALL_LEFT"]
			_set_tile_at(tile_vector, TILE_SET["WALL_LEFT"])
			continue
		elif (missing_tiles.has("RIGHT")):
			_generated_walls[tile_vector] = TILE_SET["WALL_RIGHT"]
			_set_tile_at(tile_vector, TILE_SET["WALL_RIGHT"])
			continue			
		

func _generate_floor_tiles():
	for tile_vector: Vector2 in _generated_level.keys():
		_set_tile_at(tile_vector, _generated_level[tile_vector])

# Needs a lot more logic later
func get_random_spawn_point():
	var random_tile = _generated_level.keys()[randi() % _generated_level.size()]
	return random_tile * tile_size

func _generate_rooms(rooms_left, max_retries):
	if (max_retries <= 0): return
		
	for i in range(rooms_left):
		var new_room: Rect2 = _generate_room()
		
		if _room_intersects(new_room):
			continue
			
		_add_room(new_room)
		_add_lighting(new_room)
		
		if(_generated_rooms.size() > 1): _generate_hallway(_generated_rooms[ -2 ], new_room)

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
	_generated_rooms.append(room)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			_generated_level[Vector2(x, y)] = TILE_SET["FLOOR"]
	
func _add_corridor(start, end, constant, axis):
	var _allowed_corridor_widths = range(min_corridor_width, max_corridor_width, 2)
	var _corridor_width: int = _allowed_corridor_widths[randi() % _allowed_corridor_widths.size()]
	var _startPoint: int = min(start, end)
	var _endPoint: int = max(start, end) + _corridor_width
	
	for t in range(_startPoint, _endPoint):
		for _extra_width in _corridor_width:
			match axis:
				Vector2.AXIS_X: _generated_level[Vector2(t, constant + _extra_width)] = TILE_SET["FLOOR"]
				Vector2.AXIS_Y: _generated_level[Vector2(constant + _extra_width, t)] = TILE_SET["FLOOR"]

func _room_intersects(new_room: Rect2) -> bool:
	if (_generated_rooms.size() == 0): return false
	var exists := false
	for existing_room in _generated_rooms:
		if (new_room.intersects(existing_room, true)):
			exists = true
			break
	return exists
	
func _set_tile_at(vector: Vector2, tile_atlas_coor: Vector2):
	#print(tile_map_layer.get_cell_atlas_coords(vector))
	tile_map_layer.set_cell(vector, 0, tile_atlas_coor, 0)

func _add_lighting(room):
	var room_center = room.get_center() * tile_size
	var _new_light = room_light_scene.instantiate()
	
	_new_light.position = room_center
	print(_new_light.position, _new_light)
	add_child(_new_light)
