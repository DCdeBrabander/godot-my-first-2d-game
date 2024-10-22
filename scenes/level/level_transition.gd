extends Control

signal transition_finished

var tween: Tween

func _ready():
	# Start with the ColorRect fully transparent
	$ColorRect.modulate.a = 0
	tween = Tween.new()
	#add_child(tween)
	
func fade_out(duration: float):
	# Animate fading to black
	$ColorRect.modulate.a = 0
	$ColorRect.show()  # Ensure the ColorRect is visible

	

	tween.tween_property($ColorRect, "modulate:a", 1, duration)
	tween.connect("tween_completed", _on_tween_completed)

func fade_in(duration: float):
	# Animate fading in from black
	var tween = Tween.new()
	add_child(tween)

	tween.tween_property($ColorRect, "modulate:a", 0, duration)
	tween.connect("tween_completed", _on_tween_completed)

func _on_tween_completed(tween: Tween, key: String):
	if key == "fade_out":
		emit_signal("transition_finished")
	elif key == "fade_in":
		queue_free()  # Remove the transition node if it's done
