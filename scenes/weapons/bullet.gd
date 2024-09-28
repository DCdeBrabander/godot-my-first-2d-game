extends Area2D

@export var damage: int = 1
@export var speed: Vector2 = Vector2(15, 15)

var direction: Vector2
var velocity: Vector2

func start(_position: Vector2, _direction: Vector2):
	position = _position
	direction = _direction
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += (direction.normalized() * speed) + Vector2(delta, delta)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(node_body: Node2D) -> void:
	if (node_body.is_in_group("mobs")): 
		node_body.hit(damage)
		queue_free()
