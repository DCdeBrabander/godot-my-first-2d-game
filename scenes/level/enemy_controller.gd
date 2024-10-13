extends Node2D

@onready var basic_enemy = preload("res://scenes/enemies/mob.tscn")
@onready var tile_map_layer: TileMapLayer = null

enum EnemyTypes {
	Basic,
}
var enemy_types = {
	EnemyTypes.Basic: preload("res://scenes/enemies/mob.tscn")
}

func set_current_tile_map_layer(_tile_map_layer: TileMapLayer):
	tile_map_layer = _tile_map_layer

func spawn_on_point(position: Vector2, type: EnemyTypes = EnemyTypes.Basic):
	var map_generator = get_node("../MapGenerator")
	var enemy_instance = basic_enemy.instantiate()
	enemy_instance.initialize(position)
	add_child(enemy_instance, true)
	enemy_instance.set_patrol_area(map_generator.get_area_for_position(position))
	enemy_instance.set_navigation_map(tile_map_layer.get_navigation_map())

func get_all_enemies():
	return self.get_children()

func stop_all():
	for child in get_all_enemies():	child.stop()

func kill_all():
	for child in get_all_enemies():	child.queue_free()
