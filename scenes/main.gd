extends Node

@export var mob_scene: PackedScene

@onready var Player = $Player
@onready var Level = $Level
@onready var MapGenerator = $Level/MapGenerator
@onready var MinimapLayer = $MinimapLayer
@onready var Minimap = $MinimapLayer/MapOverlay/Minimap

var is_paused := false
var viewport_size

func _ready():
	Global.add_player(Player)
	viewport_size = get_viewport().get_visible_rect()
	Level.initialize()

func _process(delta: float):
	listen_key_events()

func listen_key_events():
	if Input.is_action_just_pressed("show_map"):
		MinimapLayer.toggle()
		
	if Input.is_action_pressed("pause"):
		is_paused = !is_paused
		print("Should pause")
		#get_tree().paused = is_paused

func new_game():
	Global.set_current_score(0)
	$HUD.show_highscore(Global.get_high_score()).show_game_message("Get ready")
	Player.start(Level.get_exit_position() - Vector2(64, 64))
	$HUD.show_current_seed(Level.get_seed())
	$StartTimer.start()
	#$Music.play()

func game_over():
	$HUD.show_game_over()
	get_tree().call_group("mobs", "queue_free")
	$ScoreTimer.stop()
	$Music.stop()
	#$DeathSound.play()

func _on_score_timer_timeout():
	Global.add_score(1)

func _on_start_timer_timeout():
	$ScoreTimer.start()
