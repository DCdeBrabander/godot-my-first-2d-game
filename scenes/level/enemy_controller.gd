extends Node2D

@onready var enemy_scene = preload("res://scenes/enemies/mob.tscn")
@onready var tile_map_layer = null

func spawn_enemies(tile_map_layer_ref, spawn_points):
	# Store a reference to the TileMapLayer
	tile_map_layer = tile_map_layer_ref

	# Example: Randomly spawn 10 enemies
	for spawn_position in spawn_points:
		var enemy_instance = enemy_scene.instantiate()
		add_child(enemy_instance)
		enemy_instance.global_position = spawn_position

		# Set the navigation data for the enemy
		enemy_instance.setup_navigation(tile_map_layer)
