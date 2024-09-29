extends Node2D

var tile_size: Vector2 = Vector2(64, 64)
var level_size: Vector2 = Vector2(100, 100)

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

# Array of tile indices to use
var tile_indices: Array = []

func _ready():
	tile_map_layer.position = Vector2(0, 0)
	generate_level()

func get_tile_source_at_index(index):
	return tile_map_layer.tile_set.get_tiles_ids()
	
func generate_level():
	# Clear previous tiles
	tile_map_layer.clear() # Clears all tiles in the TileMapLaye

	for x in range(level_size.x):
		for y in range(level_size.y):
			tile_map_layer.set_cell(Vector2(x, y), 0, Vector2(0, 0), 0)

# Needs a lot more logic later
func get_spawn_point():
	return Vector2(randi_range(0, Global.get_viewport_size().x), randi_range(0, Global.get_viewport_size().y))
