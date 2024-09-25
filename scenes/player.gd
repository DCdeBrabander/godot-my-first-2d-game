extends Area2D

signal hit

@export var speed = 400
@export var bullet_cooldown = 0.25
@export var bullet: PackedScene

var screen_size
var can_shoot = true
var bullet_direction = Vector2(1, 0)

func start(_position: Vector2):
	position = _position
	show()
	$CollisionShape2D.disabled = false

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()

func _process(delta: float) -> void:
	var velocity: Vector2 = Vector2.ZERO
	var current_player_direction: Vector2 = get_player_direction()
		
	if (current_player_direction.x != 0 or current_player_direction.y != 0):
		bullet_direction = current_player_direction.normalized()
	
	if current_player_direction.length() > 0:
		velocity = current_player_direction.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	set_animation(current_player_direction)
	
	if (is_shooting()):
		shoot(bullet_direction)

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

func get_player_direction():
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

func _on_body_entered(body: Node2D) -> void:
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)
	get_tree().call_group("bullets", "queue_free")

func start_gun_cooldown():
	can_shoot = false
	$GunCooldown.start()
	
func _on_gun_cooldown_timeout() -> void:
	can_shoot = true
