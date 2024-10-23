extends Control

signal transition_finished

func fade_out(duration: float):
	print("start fade out")
	
	var tween = create_tween()

	# Animate fading to black
	$ColorRect.modulate.a = 0
	$ColorRect.show()  # Ensure the ColorRect is visible

	tween.tween_property($ColorRect, "modulate:a", 1.0, duration)
	#tween.connect("tween_completed", _on_tween_completed)
	#tween.finished.connect(callback)

func fade_in(duration: float, callback: Callable):
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate:a", 0.0, duration)
	#tween.connect("tween_completed", _on_tween_completed)
	tween.finished.connect(callback)

func _on_tween_completed(tween: Tween, key: String):
	if key == "fade_out":
		emit_signal("transition_finished")
	elif key == "fade_in":
		queue_free()  # Remove the transition node if it's done
