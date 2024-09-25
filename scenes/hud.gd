extends CanvasLayer

signal start_game

func _init():
	Global.connect("update_score", show_score)

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	return self
	
func show_highscore(score):
	$Highscore.text = "Highscore: " + str(score)
	return self
	
func show_game_over():
	show_message("Game Over")
	
	await $MessageTimer.timeout
	
	$Message.text = "Dodge those mawfucka's!"
	$Message.show()
	
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	return self

func show_score(score):
	$ScoreLabel.text = str(score)
	return self

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout() -> void:
	$Message.hide()
