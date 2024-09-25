extends CanvasLayer

signal start_game

func _init():
	Global.connect("update_score", update_score)

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func show_highscore(score):
	$Highscore.text = str(score)
	
func show_game_over():
	show_message("Game Over")
	
	await $MessageTimer.timeout
	
	$Message.text = "Dodge those mawfucka's!"
	$Message.show()
	
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout() -> void:
	$Message.hide()
