extends RigidBody2D

@export var health: int = 1
@export var score_on_kill: int = 2

enum CausesOfDeath {
	OUT_OF_BOUNDS,
	KILLED
}

var hudCanvasLayer: CanvasLayer

func initialize(hud: CanvasLayer):
	hudCanvasLayer = hud
	
func show_mob_message(text: String):
	var view_port_size = Global.get_viewport_size()
	var offset = Vector2(400, 400)
	var text_position = position
	
	if (position.x > view_port_size.x):
		text_position.x = view_port_size.x - offset.x
	elif (position.x < 0):
		text_position.x = 100
	else:
		text_position.x = position.x
	
	if (position.y > view_port_size.y):
		text_position.y = view_port_size.y - offset.y
	elif (position.y < 0): 
		text_position.y = 100
	else:
		text_position.y = position.y
		
	#hudCanvasLayer.show_one_shot_text(text, position, 2)

func _ready() -> void:
	var mob_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
	$AnimatedSprite2D.play(mob_types[randi() % mob_types.size()])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_visible_on_screen_notifier_2d_screen_exited():
	die(CausesOfDeath.OUT_OF_BOUNDS)

func hit(incoming_damage: int):
	health -= incoming_damage
	if (health <= 0):	
		die(CausesOfDeath.KILLED)
	
func die(cause_of_death: CausesOfDeath):
	match cause_of_death:
		CausesOfDeath.KILLED: Global.add_score(score_on_kill)
		CausesOfDeath.OUT_OF_BOUNDS:
			show_mob_message("-1")
			Global.subtract_score(1)
			
	queue_free()
