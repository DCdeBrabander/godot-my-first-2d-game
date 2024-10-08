extends Node

@export var mob_scene: PackedScene

@onready var Player = $Player
@onready var LevelGenerator = $LevelGenerator
@onready var MinimapLayer = $Minimap
@onready var Map = $Minimap/MapOverlay/Map

var is_paused := false
var viewport_size

func _ready():
	var viewport = get_viewport()
	viewport_size = viewport.get_visible_rect()
	
	Map.set_level_data(LevelGenerator.get_level_data())
	Map.add_marker_for_node(Player)
	
func _process(delta: float):
	listen_key_events()
	
func listen_key_events():
	if Input.is_action_just_pressed("show_map"):
		MinimapLayer.toggle()
		
	if Input.is_action_pressed("pause"):
		is_paused = !is_paused
		get_tree().paused = is_paused


# Underneath is mostly updated tutorial structure. 
# likely we want to replace/move/remove it later.
func new_game():
	Global.set_current_score(0)
	$HUD.show_highscore(Global.get_high_score()).show_game_message("Get ready")
	Player.start(LevelGenerator.get_random_spawn_point())
	$HUD.show_current_seed(str(LevelGenerator.get_current_seed()))
	$StartTimer.start()
	#$Music.play()

func game_over():
	$HUD.show_game_over()
	get_tree().call_group("mobs", "queue_free")
	$ScoreTimer.stop()
	$MobTimer.stop()
	$Music.stop()
	#$DeathSound.play()

func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate() 
	mob.initialize(LevelGenerator.get_random_spawn_point())
	add_child(mob)

func _on_score_timer_timeout():
	Global.add_score(1)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
