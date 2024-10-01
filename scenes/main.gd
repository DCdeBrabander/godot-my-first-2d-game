extends Node

@export var mob_scene: PackedScene

var viewport_size

func _ready():
	viewport_size = get_viewport().get_visible_rect()
	
func new_game():
	Global.set_current_score(0)
	$HUD.show_highscore(Global.get_high_score()).show_game_message("Get ready")
	$Player.start($LevelGenerator.get_random_spawn_point())
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
	mob.initialize($LevelGenerator.get_random_spawn_point())
	add_child(mob)

func _on_score_timer_timeout():
	Global.add_score(1)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
