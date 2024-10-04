extends RigidBody2D

@export var damage: int = 1
@export var speed: Vector2 = Vector2(25, 25)
@export var per_second = 10

var direction: Vector2
var velocity: Vector2

func start(_position: Vector2, _direction: Vector2):
	$MuzzleFlash.position = _position + _direction.normalized()
	$MuzzleFlash.show()
	$FlashTimer.start()
	position = _position
	direction = _direction.normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	#position += (direction.normalized() * speed) + Vector2(delta, delta)
	move_and_collide(direction * speed)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(node_body: RigidBody2D) -> void:
	if (node_body.is_in_group("mobs")): 
		node_body.hit(damage)
	queue_free()

func _on_flash_timer_timeout() -> void:
	$MuzzleFlash.hide()

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if (body.is_in_group("tiles")):
		# wall hit effect?
		queue_free()
