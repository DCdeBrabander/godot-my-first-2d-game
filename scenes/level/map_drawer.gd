extends Node2D

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

var tile_size = Vector2(64, 64)
var tile_map_layer: TileMapLayer
var level_data = {}

func set_tile_map_layer(_tile_map_layer: TileMapLayer):
	tile_map_layer = _tile_map_layer
	return self

func set_level_data(level: Dictionary):
	level_data = level
	return self

func draw_level():
	clear_level()
	
	set_background(generate_dark_color())
	
	_draw_floor()
	_draw_walls()
	_draw_lights()
	_draw_entry()
	_draw_exit()

func _draw_floor():
	for tile_vector: Vector2 in level_data["floor"].keys():
		_set_tile_at(tile_vector, level_data["floor"][tile_vector])

func _draw_walls():
	for tile_vector: Vector2 in level_data["walls"].keys():
		var tile_set_wall = TILE_SET[level_data["walls"][tile_vector]]
		_set_tile_at(tile_vector, tile_set_wall)

func _draw_lights():
	for tile_vector: Vector2 in level_data["lights"].keys():
		add_child(level_data["lights"][tile_vector])

func _draw_entry():
	var entry_position = level_data["entry_room"].get_center()
	Signals.level_entry_updated.emit(Rect2(entry_position * tile_size, tile_size))
	_set_tile_at(entry_position, TILE_SET.ENTRY)

func _draw_exit():
	var exit_position = level_data["exit_room"].get_center()
	Signals.level_exit_updated.emit(Rect2(exit_position * tile_size, tile_size))
	_set_tile_at(exit_position, TILE_SET.EXIT)

func generate_dark_color():
	return Color(randf_range(0.0, 0.2), randf_range(0.0, 0.2), randf_range(0.0, 0.2))
	
func set_background(color: Color):
	RenderingServer.set_default_clear_color(color)

func clear_level():
	if not "bounding_box" in level_data:
		return
	
	#for x in range(level_data["bounding_box"].position.x, level_data["bounding_box"].size.x):
		#for y in range(level_data["bounding_box"].position.y, level_data["bounding_box"].size.y):
			#tile_map_layer.set_cell(Vector2(x, y), -1, Vector2(-1, -1), -1)

	tile_map_layer.clear()
	tile_map_layer.update_internals()
	
func _set_tile_at(vector: Vector2, tile_atlas_coor: Vector2) -> void:
	tile_map_layer.set_cell(vector, 0, tile_atlas_coor, 0)
