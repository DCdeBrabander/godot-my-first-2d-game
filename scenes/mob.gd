extends RigidBody2D

@export var health: int = 1
@export var score_on_kill: int = 2

enum CausesOfDeath {
	OUT_OF_BOUNDS,
	KILLED
}

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
		CausesOfDeath.KILLED:
			Global.add_score(score_on_kill)
		CausesOfDeath.OUT_OF_BOUNDS:
			print("mob died because it went out of viewport")
	queue_free()	
