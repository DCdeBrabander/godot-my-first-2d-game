extends Area2D

@export var speed: Vector2 = Vector2(5, 5)
var direction: Vector2
var velocity: Vector2

func start(_position: Vector2, _direction: Vector2):
	position = _position
	direction = _direction
	rotation = direction.angle()

func _process(delta: float) -> void:
	velocity = (direction * speed) + Vector2(delta, delta)
	position += velocity

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("mobs"):
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
