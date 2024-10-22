extends Node2D

signal seed_update

@onready var tile_map_layer: TileMapLayer = $MapGenerator/TileMapLayer
@onready var map_generator = $MapGenerator
@onready var map_drawer = $MapDrawer
@onready var enemy_controller = $EnemyController
@onready var transition_scene = $LevelTransition

var rng: RandomNumberGenerator

var current_settings = {}
var spawn_points = []

var level_seeds = []
var current_level: int = 1
var levels = {}

# TODO Make some logic to define different level difficulties and such
func get_difficulty_settings(difficulty_level = 1):
	return {
		"current_difficulty": difficulty_level,
		"amount_enemies": 20
	}

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	_enable_level_exit_listener()
	
func randomize_seed():
	rng.randomize()
	seed_update.emit(rng.seed)
	return str(rng.seed)

# Run once when game starts (for now.)
func initialize():
	map_drawer.set_tile_map_layer(tile_map_layer)
	enemy_controller.set_current_tile_map_layer(tile_map_layer)
	
	var level_seed = randomize_seed()
	level_seeds.append(level_seed)
	generate_level_with_seed(level_seed)
	
	draw_level()

func generate_level_with_seed(seed: String):
	current_settings = get_difficulty_settings()
	levels[seed] = map_generator.generate_level(rng)

func get_current_level_data():
	return get_level_data_by_seed(get_current_level_seed())

func get_level_data_by_seed(seed):
	if not levels.has(seed):
		return null
	return levels[seed]
	
func draw_level():
	var level = get_current_level_data()
	map_drawer.set_level_data(level).draw_level()
	for i in current_settings["amount_enemies"]:
		enemy_controller.spawn_on_point(map_generator.get_random_room_spawn())

func generate_new_level():
	var level_seed = randomize_seed()
	level_seeds.append(level_seed)
	generate_level_with_seed(level_seed)

# Ok, lets generate a new level and go there!
# TODO Now we just kill all mobs, maybe we should remember them and clear them more cleanly
# TODO Update minimap (signal)
# TODO Debug why new maps are not completely generated correctly? 
func go_to_next_level():
	_disable_level_exit_listener()
	transition_scene.fade_out(1.0)
	transition_scene.connect("transition_finished", _load_next_level)
	
func _load_next_level():
	enemy_controller.kill_all()
	current_level += 1
	
	generate_new_level()
	draw_level()
	
	Signals.move_player_to.emit(get_entry_position())
	_enable_level_exit_listener()
	transition_scene.fade_in(1.0)
	
func get_entry_position():
	var level = get_current_level_data()
	return level["entry_room"].get_center() * map_generator.get_tile_size()
	
func get_exit_position():
	pass

func get_current_level() -> int:
	return current_level

func get_current_level_seed() -> String:
	return level_seeds[current_level - 1]
	
func get_seed():
	return str(rng.seed)
	
func _disable_level_exit_listener():
	Signals.player_reached_level_exit.disconnect(go_to_next_level)

func _enable_level_exit_listener():
	Signals.player_reached_level_exit.connect(go_to_next_level)
