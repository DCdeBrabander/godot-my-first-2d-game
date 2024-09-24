class_name SaveDataResource extends Resource

const SAVE_PATH:String = "user://data.tres"

# needs to be @export, otherwise it doesn't save..?
@export var data = { "high_score": 0 }

func set_save_data(_data):
	data = _data
	return self

func get_save_data():
	return data

func save() -> void:
	print("SAVING", data)
	ResourceSaver.save(self, SAVE_PATH)
	
static func load_or_create() -> SaveDataResource: 
	var res:SaveDataResource
	if FileAccess.file_exists(SAVE_PATH):
		res = load(SAVE_PATH) as SaveDataResource
	else: 
		res = SaveDataResource.new()
	return res
