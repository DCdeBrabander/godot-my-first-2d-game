extends CharacterBody2D

@export var default_speed: int = 800
@export var bullet_cooldown: float = 0.25
@export var bullet: PackedScene

@onready var player_animation = $AnimatedSprite2D
@onready var player_collision_shape = $CollisionShape2D

signal hit

enum PlayerStates {
	ALIVE,
	DEAD
}
var _current_delta: float
var screen_size

# Player stuffs
var is_slow_walking = false
var can_shoot = true
var current_speed: int
var bullet_direction = Vector2(1, 0)
var last_player_direction = Vector2.ZERO
var current_player_state = PlayerStates.DEAD
var flashlight_enabled = true

# dash mechanic
var is_dashing = false
var dash_speed = 2000
var dash_duration = 0.3
var dash_time_remaining = 0.0
var dash_cooldown: float = 1.0
var dash_cooldown_remaining: float = 1.0
var dash_direction = Vector2.ZERO

const COOLDOWN_THRESHOLD = 0.01

func _ready() -> void:
	screen_size = get_viewport_rect().size
	current_speed = default_speed
	hide()
	
func start(_position: Vector2):
	self.position = _position
	alive()

func die():
	current_player_state = PlayerStates.DEAD
	player_collision_shape.set_deferred("disabled", true)
	get_tree().call_group("bullets", "queue_free")
	hide()

func alive():
	current_player_state = PlayerStates.ALIVE
	player_collision_shape.disabled = false
	show()

func _process(delta: float) -> void:
	if (current_player_state == PlayerStates.DEAD): return
	_current_delta = delta
	
	var view_direction: Vector2 = get_mouse_direction()
	
	if dash_cooldown_remaining > 0.0:
		dash_cooldown_remaining -= delta
	
	rotate_field_of_view(view_direction)	
	handle_actions_from_input()
	move_player()
	set_animation(view_direction)

func handle_actions_from_input():
	if Input.is_action_pressed("slow_walk"): set_slow_walk(true)
	else: set_slow_walk(false)
	
	if Input.is_action_just_pressed("flashlight"): toggle_flashlight()
	if Input.is_action_just_pressed("dash"): start_dash()
	if Input.is_action_pressed("fire"): shoot()
	
func move_player():
	var current_player_direction: Vector2 = get_move_direction()
	var player_velocity: Vector2 = Vector2.ZERO
	
	# refactor logic so it can use same bottom move_and_collide and speed (like is_slow_walking)
	if is_dashing:
		# Dash in the set direction		
		player_velocity = current_player_direction.normalized() * dash_speed
		dash_time_remaining -= _current_delta
	
		# If dash time runs out, stop dashing
		if is_zero_approx(abs(dash_time_remaining)) or dash_time_remaining <= COOLDOWN_THRESHOLD:
			is_dashing = false
			
		move_and_collide(player_velocity * _current_delta)
		return
	
	if is_slow_walking:
		current_speed = default_speed / 2
	else: 
		current_speed = default_speed

	if current_player_direction.length() > 0:
		player_velocity = current_player_direction.normalized() * current_speed
		move_and_collide(player_velocity * _current_delta)
		Global.update_player_position(self.position)
		player_animation.play()
	else: player_animation.stop()

func start_dash():
	if is_dashing or dash_cooldown_remaining > COOLDOWN_THRESHOLD:
		return

	# Only start dash if there's a direction
	if get_move_direction() != Vector2.ZERO:
		is_dashing = true
		dash_time_remaining = dash_duration
		dash_cooldown_remaining = dash_cooldown
		
func set_slow_walk(is_slow: bool):
	is_slow_walking = is_slow
	
func toggle_flashlight():
	flashlight_enabled = ! flashlight_enabled
	$FieldOfView.enabled = flashlight_enabled
	
func rotate_field_of_view(direction: Vector2, smoothing_scale: float = 0.1):
	if ! $FieldOfView.enabled: return
	
	var scale = Vector2(1, 1)
	var offset = Vector2(350, 0)
	
	$FieldOfView.scale = scale
	$FieldOfView.offset = offset
	$FieldOfView.position = self.position.normalized()
	$FieldOfView.rotation = lerp_angle($FieldOfView.rotation, direction.angle(), smoothing_scale)

func shoot():
	if not can_shoot: return
	
	var direction: Vector2 = get_mouse_direction()
	
	var bullet_instance = bullet.instantiate()
	get_tree().root.add_child(bullet_instance)
	var start_position = (self.position + Vector2(100  * direction.normalized().x, 100 * direction.normalized().y))
	bullet_instance.start(start_position, direction)
	
	start_gun_cooldown()

func set_animation(velocity):
	if velocity.x != 0:
		player_animation.animation = "walk"
		player_animation.flip_v = false
		player_animation.flip_h = velocity.x < 0
	elif velocity.y != 0:
		player_animation.animation = "up"
		player_animation.flip_v = velocity.y > 0

func get_move_direction():
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"): velocity.x += 1
	if Input.is_action_pressed("move_left"): velocity.x -= 1
	if Input.is_action_pressed("move_down"): velocity.y += 1
	if Input.is_action_pressed("move_up"): velocity.y -= 1
	return velocity
	
func get_mouse_direction() -> Vector2:
	return get_global_mouse_position() - position

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("mobs")):
		hit.emit()
		die()

func start_gun_cooldown():
	can_shoot = false
	$GunCooldown.start()
	
func _on_gun_cooldown_timeout() -> void:
	can_shoot = true

func get_minimap_indicator_style() -> Dictionary:
	return {
		"size": Vector2(10, 10),
		"color": Color(1, 0, 0),
		"animate": "pulse"
	}
