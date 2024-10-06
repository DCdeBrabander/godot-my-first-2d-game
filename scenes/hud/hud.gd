extends CanvasLayer

signal start_game

func _init():
	Global.connect("update_score", show_score)

func show_one_shot_text(_text, _position, _duration):
	var label =	Label.new()
	
	label.text = _text
	label.position = _position
	label.set("theme_override_font_sizes/font_size", 80)
	add_child(label)
	
	label.show()
	await Global.run_one_shot_timer(_duration)
	label.hide()
	label.queue_free()
	
func show_score(score):
	$ScoreLabel.text = str(score)
	if (score > Global.high_score):
		show_highscore(score)
	return self
	
func show_game_message(text):
	$GameMessage.text = text
	$GameMessage.show()
	$MessageTimer.start()
	return self
	
func show_new_highscore_message():
	$NewHighScoreLabel.show()
	return self
	
func show_highscore(score):
	$Highscore.text = "Highscore: " + str(score)
	return self
	
func show_game_over():
	show_game_message("Game Over")
	
	if (Global.is_high_score()):
		Global.save_high_score()
		show_new_highscore_message()

	await $MessageTimer.timeout
	
	$GameMessage.text = "Dodge those mawfucka's!"
	$GameMessage.show()
	$StartButton.show()
	
	return self

func show_current_seed(seed: String):
	$CurrentSeed.text = seed

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	$NewHighScoreLabel.hide()
	start_game.emit()

func _on_message_timer_timeout() -> void:
	$GameMessage.hide()
