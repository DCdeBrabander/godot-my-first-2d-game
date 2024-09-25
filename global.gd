extends Node

signal update_score

var high_score_key := "high_score"
var high_score = 0
var current_score = 0
var save_resource: SaveDataResource

func add_score(add: int):
	current_score += add
	update_score.emit(current_score)
	
func set_current_score(score: int): 
	current_score = score
	update_score.emit(current_score)
	
func keep_high_score():
	if current_score <= high_score:
		return

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
