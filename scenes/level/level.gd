extends Node2D

@onready var tile_map_layer: TileMapLayer = $MapGenerator/TileMapLayer
@onready var map_generator = $MapGenerator
@onready var enemy_controller = $EnemyController

var spawn_points = []

func get_difficulty_settings(difficulty_level = 1):
	return {
		"current_difficulty": difficulty_level,
		"amount_enemies": 20
	}

func generate_new_level():
	var settings = get_difficulty_settings()
	
	#map_generator.set_tile_map_layer(tile_map_layer)
	map_generator.generate_level()
	
	for i in settings["amount_enemies"]:
		spawn_points.append(map_generator.get_random_spawn_point())
		
	enemy_controller.spawn_random_enemy_per_point(tile_map_layer, spawn_points)
	
func get_level():
	return map_generator.get_level_data()
