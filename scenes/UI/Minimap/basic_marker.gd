extends Node2D

@export var marker_color: Color = Color(0, 0, 0)

func _draw() -> void:
	draw_circle(Vector2(0, 0), 10, marker_color)

func set_color(color: Color):
	marker_color = color
