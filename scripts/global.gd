extends Node

signal update_score
signal move_player_position

var high_score_key := "high_score"
var high_score = 0
var current_score = 0
var save_resource: SaveDataResource
var player_position: Vector2 = Vector2.ZERO

func _init():
	high_score = get_high_score()
	
func is_high_score() -> bool:
	return high_score < current_score

func subtract_score(subtract: int):
	current_score -= subtract
	update_score.emit(current_score)
	
func add_score(add: int):
	current_score += add
	update_score.emit(current_score)
	
func set_current_score(score: int): 
	current_score = score
	update_score.emit(current_score)
	
func save_high_score():
	if ! is_high_score(): return
	high_score = current_score
	get_save_data_resource().set_save_data({ high_score_key: high_score }).save()

func get_high_score():
	var data = get_save_data_resource().get_save_data()
	var has_saved_high_score = data.has(high_score_key) and data[high_score_key] > 0
	if (has_saved_high_score):
		return data[high_score_key]
	return high_score

func get_save_data_resource() -> SaveDataResource:
	save_resource = SaveDataResource.load_or_create()
	return save_resource

func run_one_shot_timer(time: float = 1.0):
	await get_tree().create_timer(time).timeout

func get_viewport_size() -> Vector2: 
	return get_viewport().get_visible_rect().size
	
func update_player_position(position):
	player_position = position

func move_player_to(position):
	update_player_position(position)
	move_player_position.emit(position)
	
func get_current_player_position():
	return player_position
