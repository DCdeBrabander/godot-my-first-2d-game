extends CharacterBody2D

@export var speed = 800
@export var bullet_cooldown = 0.25
@export var bullet: PackedScene

@onready var fov_light := $FieldOfViewLight

signal hit

enum PlayerStates {
	ALIVE,
	DEAD
}

var screen_size
var can_shoot = true
var bullet_direction = Vector2(1, 0)
var last_player_direction = Vector2.ZERO
var current_player_state = PlayerStates.DEAD
var flashlight_enabled = true

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()
	
func start(_position: Vector2):
	self.position = _position
	alive()

func die():
	current_player_state = PlayerStates.DEAD
	$CollisionShape2D.set_deferred("disabled", true)
	get_tree().call_group("bullets", "queue_free")
	hide()

func alive():
	current_player_state = PlayerStates.ALIVE
	$CollisionShape2D.disabled = false
	show()

func _process(delta: float) -> void:
	if (current_player_state == PlayerStates.DEAD): return
	
	var view_direction: Vector2 = get_mouse_direction()

	toggle_flashlight()
	move_player(delta)
	rotate_field_of_view(view_direction)
	set_animation(view_direction)
		
	if (is_shooting()): shoot(view_direction)
	
func move_player(delta: float):
	var current_player_direction: Vector2 = get_move_direction()
	var player_velocity: Vector2 = Vector2.ZERO

	if current_player_direction.length() > 0:
		player_velocity = current_player_direction.normalized() * speed
		move_and_collide(player_velocity * delta)
		Global.update_player_position(self.position)
		$AnimatedSprite2D.play()
	else: $AnimatedSprite2D.stop()

func toggle_flashlight():
	if Input.is_action_just_pressed("flashlight"):
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

func is_shooting() -> bool:
	return Input.is_action_pressed("fire") && can_shoot

func shoot(direction: Vector2):
	var bullet_instance = bullet.instantiate()
	get_tree().root.add_child(bullet_instance)
	var start_position = (self.position + Vector2(100  * direction.normalized().x, 100 * direction.normalized().y))
	bullet_instance.start(start_position, direction)
	start_gun_cooldown()

func set_animation(velocity):
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

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
