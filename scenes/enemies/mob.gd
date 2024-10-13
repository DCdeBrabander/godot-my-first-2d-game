extends CharacterBody2D

@onready var navigation_agent = $NavigationAgent2D

var movement_delta: float
@export var movement_speed: float = 4.0

@export var health: int = 1
@export var score_on_kill: int = 2
@export var speed = 10

var current_behaviour: Behaviour = Behaviour.PATROL
var patrol_area: Rect2

enum CausesOfDeath {
	OUT_OF_BOUNDS,
	KILLED
}

enum Behaviour {
	FOLLOW,
	PATROL,
	STOPPED,
}

func _ready() -> void:
	var mob_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
	$AnimatedSprite2D.play(mob_types[randi() % mob_types.size()])
	
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	Signals.mob_created.emit(self.get_instance_id())

func _physics_process(delta: float): 
	match current_behaviour:
		Behaviour.PATROL: patrol()
		Behaviour.FOLLOW: follow()
		_: print("no behaviour")

	# Move the character with the computed velocity
	move_and_slide()

func initialize(position: Vector2, behaviour: Behaviour = Behaviour.PATROL) -> CharacterBody2D:
	self.position = position
	current_behaviour = behaviour
	return self

func patrol():
	if patrol_area == null:
		print("Patrol area not set for enemy...")
		return

	if navigation_agent.is_navigation_finished() or navigation_agent.is_target_reached() or velocity == Vector2.ZERO:
		var patrol_point = get_random_patrol_point() * 64
		if (patrol_point == Vector2.ZERO):
			print("shit's zero boss..", patrol_point)
			
		# Set a new patrol point when the target is reached
		navigation_agent.set_target_position(patrol_point)
		
		# Calculate movement delta
		movement_delta = speed * get_process_delta_time()  # Use speed defined in the script

		# Get the next path position from the navigation agent
		var next_path_position: Vector2 = navigation_agent.get_next_path_position()

		# Calculate the new velocity towards the next path position
		var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_delta
		
		_on_velocity_computed(new_velocity)
	
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	
func stop():
	current_behaviour = Behaviour.STOPPED
	velocity = Vector2.ZERO
	return self
	
func follow():
	print("?")

func get_random_patrol_point() -> Vector2:
	return patrol_area.position + Vector2(randf() * patrol_area.size.x, randf() * patrol_area.size.y)
	
func hit(incoming_damage: int):
	print("HIT")
	health -= incoming_damage
	if (health <= 0): die(CausesOfDeath.KILLED)
	
func die(cause_of_death: CausesOfDeath):
	match cause_of_death:
		CausesOfDeath.KILLED: Global.add_score(score_on_kill)
	
	print("DIE")
	queue_free()

func set_navigation_map(navigation_map: RID) -> CharacterBody2D:
	navigation_agent.set_navigation_map(navigation_map)
	return self

func set_patrol_area(area: Rect2):
	patrol_area = area
	return self	
	
func get_minimap_indicator_style() -> Dictionary:
	return {
		"size": Vector2(10, 10),
		"color": Color(0, 1, 0),
		"animate": "pulse"
	}

func _exit_tree() -> void:
	print("Mob is being freed: ", self)
