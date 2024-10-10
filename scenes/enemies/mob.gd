extends CharacterBody2D

@export var health: int = 1
@export var score_on_kill: int = 2

var current_behaviour: Behaviour = Behaviour.FOLLOW

@onready var navigation_agent = $NavigationAgent2D

enum CausesOfDeath {
	OUT_OF_BOUNDS,
	KILLED
}

enum Behaviour {
	FOLLOW,
	PATROL
}

func setup_navigation(tile_map_layer: TileMapLayer):
	# Assign the TileMapLayer's navigation map to the NavigationAgent2D
	var navigation_map = tile_map_layer.navigation_map
	navigation_agent.navigation_map = navigation_map

func patrol():
	if navigation_agent.is_target_reached():
		# Set a new random patrol point
		var patrol_target = get_random_patrol_point()
		navigation_agent.set_target_location(patrol_target)

	move_towards_target()

func move_towards_target():
	var direction = (navigation_agent.get_next_path_position() - global_position).normalized()
	move_and_slide(direction * 100)  # Example patrol speed

func get_random_patrol_point() -> Vector2:
	# Generate a random point within a predefined patrol area
	var patrol_area = Rect2(Vector2(100, 100), Vector2(500, 500))  # Example patrol area
	return patrol_area.position + Vector2(randf() * patrol_area.size.x, randf() * patrol_area.size.y)
	
#func initialize(start_position: Vector2):
	#position = start_position
	#velocity = Vector2(randf_range(1, 3), randf_range(1, 3))
	#
#func show_mob_message(text: String):
	#var view_port_size = Global.get_viewport_size()
	#var offset = Vector2(400, 400)
	#var text_position = position
	#
	#if (position.x > view_port_size.x):
		#text_position.x = view_port_size.x - offset.x
	#elif (position.x < 0):
		#text_position.x = 100
	#else:
		#text_position.x = position.x
	#
	#if (position.y > view_port_size.y):
		#text_position.y = view_port_size.y - offset.y
	#elif (position.y < 0): 
		#text_position.y = 100
	#else:
		#text_position.y = position.y
		#
	##hudCanvasLayer.show_one_shot_text(text, position, 2)
#
#func _ready() -> void:
	#var mob_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
	#$AnimatedSprite2D.play(mob_types[randi() % mob_types.size()])
	#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#match (current_behaviour):
		#Behaviour.FOLLOW: move_to(Global.player_position, delta)
#
#func move_to(new_position: Vector2, delta: float):
	#var distance = new_position - position
	#var new_velocity = distance.normalized() * velocity
	#position += new_velocity + Vector2(delta, delta)
#
#func _on_visible_on_screen_notifier_2d_screen_exited():
	#pass
	##die(CausesOfDeath.OUT_OF_BOUNDS)
#
#func hit(incoming_damage: int):
	#health -= incoming_damage
	#if (health <= 0): die(CausesOfDeath.KILLED)
	#
#func die(cause_of_death: CausesOfDeath):
	#match cause_of_death:
		#CausesOfDeath.KILLED: Global.add_score(score_on_kill)
		#CausesOfDeath.OUT_OF_BOUNDS:
			#show_mob_message("-1")
			#Global.subtract_score(1)
			#
	#queue_free()
