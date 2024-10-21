extends Node2D

signal seed_update

@onready var tile_map_layer: TileMapLayer = $MapGenerator/TileMapLayer
@onready var map_generator = $MapGenerator
@onready var map_drawer = $MapDrawer
@onready var enemy_controller = $EnemyController

var rng: RandomNumberGenerator

var current_settings = {}
var spawn_points = []

var current_level_seed
var levels = {}

# TODO Make some logic to define different level difficulties and such
func get_difficulty_settings(difficulty_level = 1):
	return {
		"current_difficulty": difficulty_level,
		"amount_enemies": 20
	}

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	
func randomize_seed():
	rng.randomize()
	seed_update.emit(rng.seed)
	return str(rng.seed)

# Run once when game starts	(for now.)
func initialize():
	map_drawer.set_tile_map_layer(tile_map_layer)
	enemy_controller.set_current_tile_map_layer(tile_map_layer)
	current_level_seed = randomize_seed()
	generate_level_with_seed(current_level_seed)
	draw_level()

func generate_level_with_seed(seed: String):
	current_settings = get_difficulty_settings()
	levels[seed] = map_generator.generate_level(rng)

func get_current_level():
	return get_level_data_by_seed(current_level_seed)

func get_level_data_by_seed(seed):
	if not levels.has(seed):
		return null
	return levels[seed]
	
func draw_level():
	var level = get_level_data_by_seed(current_level_seed)
	map_drawer.set_level_data(level).draw_level()
	for i in current_settings["amount_enemies"]:
		enemy_controller.spawn_on_point(map_generator.get_random_room_spawn())
	
func get_entry_position():
	var level = get_level_data_by_seed(current_level_seed)
	return level["entry_room"].get_center() * map_generator.get_tile_size()
	
func get_exit_position():
	pass
	
func get_seed():
	return str(rng.seed)
