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

enum ActionStates {
	SLOW_WALKING,
	NORMAL_WALKING,
	DASHING,
	CROUCHING,
}

var _current_delta: float
var screen_size

# inventory action thingz (maybe abstract later)
var can_shoot = true
var flashlight_enabled = true

var current_speed: int
var bullet_direction = Vector2(1, 0)
var last_player_direction = Vector2.ZERO
var current_player_state: PlayerStates = PlayerStates.DEAD
var current_action_state: ActionStates = ActionStates.NORMAL_WALKING

# dash mechanic
var dash_speed = 2000
var dash_duration: float = 0.3
var dash_cooldown: float = 1.0
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 1.0
var dash_direction := Vector2.ZERO

# Workaround for float inaccuracy (is_approx_zero() isnt reliable?)
const COOLDOWN_THRESHOLD = 0.01
const DELTA_EPSILON = 0.01

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
	if (current_player_state == PlayerStates.DEAD):
		return
	
	_current_delta = delta

	update_cooldowns()
	handle_actions_from_input()
	rotate_field_of_view()
	move_player()

func handle_actions_from_input():
	if not is_dashing():
		if Input.is_action_just_pressed("dash"): start_dash()
		elif Input.is_action_pressed("slow_walk"): set_action_state(ActionStates.SLOW_WALKING)
		elif Input.is_action_pressed("crouch"): set_action_state(ActionStates.CROUCHING)
		else: set_action_state(ActionStates.NORMAL_WALKING)
	
	if Input.is_action_just_pressed("flashlight"): toggle_flashlight()
	if Input.is_action_pressed("fire"): shoot()

func update_cooldowns():
	if dash_cooldown_remaining > COOLDOWN_THRESHOLD: dash_cooldown_remaining -= _current_delta
	else: set_action_state(ActionStates.NORMAL_WALKING)

func move_player():
	var current_player_direction: Vector2 = get_move_direction()
	var player_velocity: Vector2 = Vector2.ZERO
	current_speed = default_speed
	
	match(current_action_state):
		ActionStates.DASHING:
			if (is_dashing()): current_speed = dash_speed
		ActionStates.CROUCHING: current_speed = 0
		ActionStates.SLOW_WALKING: current_speed = default_speed / 2

	if current_player_direction.length() <= 0:
		player_animation.stop()
		return
		
	if current_speed > 0:
		player_animation.play()
	
	player_velocity = current_player_direction.normalized() * current_speed * _current_delta
	move_and_collide(player_velocity)
	set_animation(get_mouse_direction())
	Global.update_player_position(self.position)

func start_dash():
	if is_dashing():
		return

	# Only start dash if there's a direction
	if get_move_direction() == Vector2.ZERO:
		return
		
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	set_action_state(ActionStates.DASHING)

func is_dashing() -> bool:
	if current_action_state != ActionStates.DASHING:
		return false
		
	if (dash_time_remaining <= DELTA_EPSILON):
		return false
		
	dash_time_remaining -= _current_delta
	return true

func set_action_state(action_state: ActionStates):
	current_action_state = action_state

func toggle_flashlight():
	flashlight_enabled = ! flashlight_enabled
	$FieldOfView.enabled = flashlight_enabled
	
func rotate_field_of_view(smoothing_scale: float = 0.1):
	if ! $FieldOfView.enabled: return
	
	var scale = Vector2(1, 1)
	var offset = Vector2(350, 0)
	
	$FieldOfView.scale = scale
	$FieldOfView.offset = offset
	$FieldOfView.position = self.position.normalized()
	$FieldOfView.rotation = lerp_angle($FieldOfView.rotation, get_mouse_direction().angle(), smoothing_scale)

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
