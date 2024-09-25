extends Node

@export var mob_scene: PackedScene

var viewport_size

func _ready():
	viewport_size = get_viewport().get_visible_rect()
	
func new_game():
	Global.set_current_score(0)
	$HUD.show_highscore(Global.get_high_score()).show_message("Get ready")
	$Player.start(viewport_size.get_center())
	$StartTimer.start()
	get_tree().call_group("mobs", "queue_free")
	
func game_over():
	Global.keep_high_score()
	$HUD.show_game_over()
	$ScoreTimer.stop()
	$MobTimer.stop()
	$Music.stop()
	$DeathSound.play()

func _on_mob_timer_timeout() -> void:
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Set the mob's position to a random location.
	mob.position = mob_spawn_location.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

func _on_score_timer_timeout():
	Global.add_score(1)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
