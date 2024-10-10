extends Node2D

@onready var enemy_scene = preload("res://scenes/enemies/mob.tscn")
@onready var tile_map_layer = null

func spawn_random_enemy_per_point(tile_map_layer_ref, spawn_points):
	tile_map_layer = tile_map_layer_ref

	for spawn_position in spawn_points:
		var enemy_instance = enemy_scene.instantiate()
		add_child(enemy_instance)
		enemy_instance.create(spawn_position).setup_navigation(tile_map_layer)


func get_all_enemies():
	return self.get_children()

func stop_all():
	for child in get_all_enemies():
		child.stop()
