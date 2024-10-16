extends CharacterBody2D

@onready var navigation_agent = $NavigationAgent2D

@export var movement_speed: float = 40000.0
@export var health: int = 2
@export var score_on_kill: int = 2
@export var visibility_distance = 1000
@export var look_around_duration = 5.0

var current_behaviour: Behaviour = Behaviour.PATROL
var previous_behaviour: Behaviour

var movement_delta: float
var patrol_area: Rect2
var current_follow_target: Node
var look_around_timeout_left = 0.0
var follow_last_known_position = Vector2.ZERO

var world_space_state: PhysicsDirectSpaceState2D

const DELTA_EPSILON = 0.01

enum CausesOfDeath {
	OUT_OF_BOUNDS,
	KILLED
}

enum Behaviour {
	FOLLOW,
	PATROL,
	STOPPED,
	LOOK_AROUND,
}

func _exit_tree() -> void:
	print("Mob is being freed: ", self)
	
func _ready() -> void:
	var mob_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
	$AnimatedSprite2D.play(mob_types[randi() % mob_types.size()])
	
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	world_space_state = get_world_2d().direct_space_state
	Signals.mob_created.emit(self.get_instance_id())

func _physics_process(delta: float): 
	update_behaviour(delta)
	
	match current_behaviour:
		Behaviour.PATROL: patrol()
		Behaviour.FOLLOW: follow()
		Behaviour.LOOK_AROUND: look_around()
		_: print("no behaviour")

func initialize(position: Vector2, behaviour: Behaviour = Behaviour.PATROL) -> CharacterBody2D:
	self.position = position
	current_behaviour = behaviour
	return self

# Debug / TODO Replace for actual light source (like player)
func _draw():
	# Convert FOV angle to radians
	var fov_angle = 60 * PI / 180
	var fov_radius = visibility_distance
	var fov_color = Color(1, 1, 0, 0.1)  # Semi-transparent yellow color

	# Calculate the left and right directions of the cone
	var direction_left = Vector2(cos(rotation - fov_angle / 2), sin(rotation - fov_angle / 2))
	var direction_right = Vector2(cos(rotation + fov_angle / 2), sin(rotation + fov_angle / 2))

	var cone_polygon_points = [
		Vector2(),  # The mob's position (origin of the cone)
		direction_left * fov_radius,  # The left edge of the cone
		direction_right * fov_radius  # The right edge of the cone
	]

	# Draw the filled cone (polygon) as a triangle
	draw_polygon(cone_polygon_points, [fov_color])

func update_behaviour(delta: float):
	var player_in_view
	current_follow_target = null
	
	for player in get_tree().get_nodes_in_group("players"):
		if is_in_view(player):
			previous_behaviour = current_behaviour
			current_behaviour = Behaviour.FOLLOW
			current_follow_target = player
			break
	
	if not current_follow_target:
		# we were following something, let's start looking around
		if current_behaviour == Behaviour.FOLLOW:
			current_behaviour = Behaviour.LOOK_AROUND
			look_around_timeout_left = look_around_duration
			
		
		# Lets look around for a bit before going back
		elif current_behaviour == Behaviour.LOOK_AROUND:
			look_around_timeout_left -= delta
			if look_around_timeout_left <= DELTA_EPSILON:
				current_behaviour = Behaviour.PATROL
		
		# Fall back to default behaviour, which is patrolling
		elif (current_behaviour != Behaviour.PATROL):
			current_behaviour = Behaviour.PATROL

	if previous_behaviour != current_behaviour:
		previous_behaviour = current_behaviour

func patrol():
	if patrol_area == null:
		print("Patrol area not set for enemy...")
		return
	
	if navigation_agent.is_navigation_finished() or velocity.is_zero_approx():
		navigation_agent.set_target_position(get_random_patrol_point() * 64)

	if not navigation_agent.is_target_reachable() or navigation_agent.is_target_reached():
		navigation_agent.set_target_position(get_random_patrol_point() * 64)

	movement_delta = movement_speed * get_process_delta_time()
	
	var new_velocity: Vector2 = global_position.direction_to(navigation_agent.get_next_path_position()) * movement_delta
	navigation_agent.set_velocity(new_velocity)
	_lerp_rotation(global_position.direction_to(navigation_agent.get_next_path_position()).angle())

func look_around():
	if follow_last_known_position:
		navigation_agent.set_target_position(follow_last_known_position)
		_lerp_rotation(global_position.direction_to(follow_last_known_position).angle())
		follow_last_known_position = null
		return
	
	# if mob is at last known position of node it followed, start looking around
	# face different direction every whole second
	# needs some work.. (it still constantly runs)
	if navigation_agent.is_navigation_finished():
		if int(look_around_timeout_left) == snapped(look_around_timeout_left, 0.5):
			_lerp_rotation(randf_range(-PI, PI))

func stop():
	current_behaviour = Behaviour.STOPPED
	velocity = Vector2.ZERO
	return self
	
func follow():
	if current_follow_target == null:
		return
	
	follow_last_known_position = current_follow_target.global_position
	navigation_agent.set_target_position(current_follow_target.global_position)

	# Check if the target is reachable or the mob has reached the player
	if navigation_agent.is_target_reachable() and not navigation_agent.is_navigation_finished():
		movement_delta = movement_speed * get_process_delta_time()
		var new_velocity: Vector2 = global_position.direction_to(navigation_agent.get_next_path_position()) * movement_delta
		navigation_agent.set_velocity(new_velocity)
		_lerp_rotation(global_position.direction_to(navigation_agent.get_next_path_position()).angle())
	else:
		# Handle unreachable target or if the target has been reached
		navigation_agent.set_velocity(Vector2.ZERO)

func hit(incoming_damage: int):
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
	
func get_random_patrol_point(padding: float = 2.0) -> Vector2:
	var clamped_min = patrol_area.position + Vector2(padding, padding)
	var clamped_max = patrol_area.position + patrol_area.size - Vector2(padding, padding)
	return Vector2(
		randf_range(clamped_min.x, clamped_max.x),
		randf_range(clamped_min.y, clamped_max.y)
	)

# check distance and in FOV
func is_in_view(node: Node2D) -> bool:
	if (global_position - node.global_position).length_squared() > visibility_distance * visibility_distance:
		return false
	
	# Raycast to check if there are any obstacles between the mob and the player
	var ray_length = (node.global_position - global_position).length()  # Length of the ray
	var result = world_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, node.global_position))
	
	var direction_to_player = (node.global_position - global_position).normalized()
	var mob_facing_direction = Vector2(cos(rotation), sin(rotation)).normalized()
	# Dot product to check if the player is within the FOV cone
	var dot_product = mob_facing_direction.dot(direction_to_player)
	# Check the FOV angle (cosine of half the FOV angle)
	var fov_angle = 60 * PI / 180  # Convert degrees to radians
	var fov_cosine = cos(fov_angle / 2)

	# Return true if the player is within FOV and if ray hit the node (like Player)
	return dot_product >= fov_cosine and (result and result.collider == node)

func _lerp_rotation(to_rotation: float, smoothing_scale: float = 0.3) -> void:
	rotation = lerp_angle(rotation, to_rotation, smoothstep(0.0, 1.0, smoothing_scale))

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
