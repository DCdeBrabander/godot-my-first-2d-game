extends Area2D

signal hit

enum PLAYER_STATES {
	ALIVE,
	DEAD
}

@export var speed = 400
@export var bullet_cooldown = 0.25
@export var bullet: PackedScene

@onready var fov_light := $FieldOfViewLight

var screen_size
var can_shoot = true
var bullet_direction = Vector2(1, 0)
var last_player_direction = Vector2.ZERO
var current_player_state = PLAYER_STATES.DEAD

func start(_position: Vector2):
	position = _position
	alive()

func die():
	current_player_state = PLAYER_STATES.DEAD
	$CollisionShape2D.set_deferred("disabled", true)
	get_tree().call_group("bullets", "queue_free")
	hide()

func alive():
	current_player_state = PLAYER_STATES.ALIVE
	$CollisionShape2D.disabled = false
	show()

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()

func _process(delta: float) -> void:
	if (current_player_state == PLAYER_STATES.DEAD): return
	
	var view_direction: Vector2 = get_mouse_direction()

	move_player(delta)
	rotate_field_of_view(view_direction)
	set_animation(view_direction)
		
	if (is_shooting()): shoot(view_direction)

func move_player(delta):
	var current_player_direction: Vector2 = get_move_direction()
	var player_velocity: Vector2 = Vector2.ZERO

	if current_player_direction.length() > 0:
		player_velocity = current_player_direction.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += player_velocity * delta
	Global.set_current_player_position(position)

func rotate_field_of_view(direction: Vector2, smoothing_scale: float = 0.1):
	var scale = Vector2(1, 1)
	var offset = Vector2(350, 0)
	
	$FieldOfView.scale = scale
	$FieldOfView.offset = offset
	$FieldOfView.position = position.normalized()
	$FieldOfView.rotation = lerp_angle($FieldOfView.rotation, direction.angle(), smoothing_scale)

func is_shooting() -> bool:
	return Input.is_action_pressed("fire") && can_shoot

func shoot(direction: Vector2):
	var bullet_instance = bullet.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.start(position, direction) 
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
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
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
