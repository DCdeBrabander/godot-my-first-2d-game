extends CanvasLayer

@onready var map_overlay = $MapOverlay
@onready var map = $MapOverlay/Map

func _ready():
	Signals.level_generated.connect(update_map)
	map_overlay.visible = false

func update_map(level_data):
	var level_size = level_data["bounding_box"].size #get_node("../Level/MapGenerator").get_level_size()
	var map_overlay_size = $MapOverlay.size
	
	# Calculate the scaling factor based on the ratio of world size to map overlay size
	var scale_factor_x = (map_overlay_size.x / level_size.x) / 64
	var scale_factor_y = (map_overlay_size.y / level_size.y) / 64
	
	# Use the smaller of the two scale factors to ensure the world fits within the map overlay
	var map_scale = min(scale_factor_x, scale_factor_y)
	
	map.set_map_scale(map_scale)
	map.set_world_size(level_size)
	map.set_map_size(map_overlay.size)
	map.position = (map_overlay_size - (level_size * map_scale)) / 2

func toggle():
	map_overlay.visible = !map_overlay.visible
