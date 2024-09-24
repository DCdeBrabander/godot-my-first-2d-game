extends Area2D

signal hit

@export var speed = 400
@export var bullet_cooldown = 0.25
@export var bullet: PackedScene

var screen_size # Size of the game window.
var can_shoot = true
var last_shoot_direction = Vector2(1, 0)

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var velocity: Vector2 = Vector2.ZERO
	var direction: Vector2 = calc_direction()
	
	if direction.length() > 0:
		velocity = direction.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	set_animation(direction)
	
	if (is_shooting()):
		shoot(direction)

func is_shooting() -> bool:
	return Input.is_action_pressed("fire") && can_shoot

func shoot(direction: Vector2):
	var bullet_direction = direction 
	
	if (bullet_direction.x == 0 and bullet_direction.y == 0):
		bullet_direction = last_shoot_direction
	else:
		last_shoot_direction = bullet_direction
		
	var bullet_instance = bullet.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.start(position, bullet_direction) 
	start_gun_cooldown()

func set_animation(velocity):
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		# See the note below about the following boolean assignment.
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

func calc_direction():
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
