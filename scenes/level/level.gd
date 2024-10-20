extends Node2D

@onready var tile_map_layer: TileMapLayer = $MapGenerator/TileMapLayer
@onready var map_generator = $MapGenerator
@onready var enemy_controller = $EnemyController

var spawn_points = []
var current_level_data = {}

func get_difficulty_settings(difficulty_level = 1):
	return {
		"current_difficulty": difficulty_level,
		"amount_enemies": 20
	}

func generate_new_level():
	var settings = get_difficulty_settings()
	
	# TODO: generate_level currently immediately draws, maybe abstract to seperate drawer
	# 		Why: able to pre-generate certain seed before actually drawing
	current_level_data = map_generator.generate_level()
	enemy_controller.set_current_tile_map_layer(tile_map_layer)
	
	for i in settings["amount_enemies"]:
		enemy_controller.spawn_on_point(map_generator.get_random_room_spawn())

func get_entry_position():
	return current_level_data["entry_room"].get_center() * map_generator.get_tile_size()
	
func get_exit_position():
	pass
	
func get_level():
	return current_level_data
	
func get_seed():
	return str(map_generator.get_current_seed())
