extends Node2D

@export var marker_color: Color = Color(0, 0, 0)
@export var animation_type: String
@export var circle_radius: float = 10
var size_tween: Tween

func _ready() -> void:
	size_tween = get_tree().create_tween().bind_node(self).set_loops().set_trans(Tween.TRANS_SINE)
	if animation_type.length: start_animation()
	
func _draw() -> void:
	draw_circle(Vector2(0, 0), circle_radius, marker_color)
	
func _process(_delta):
	queue_redraw()
	
func set_color(color: Color):
	marker_color = color

func set_animation(_animation_name: String):
	animation_type = _animation_name
	
func start_animation():
	if (animation_type == "pulse"): _animate_pulse()

func stop_animation():
	size_tween.stop()
	size_tween.tween_callback(self.queue_free)

func _animate_pulse():
	size_tween.tween_property(self, "circle_radius", 12, 1)
	size_tween.tween_property(self, "circle_radius", 10, 1)

func _exit_tree() -> void:
	print("_exit_tree in basic marker")
