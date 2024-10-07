extends CanvasLayer

@onready var map_overlay = $MapOverlay
@onready var level_representation = $MapOverlay/LevelRepresentation

func _ready():
	map_overlay.visible = false

	var level_size = get_node("../LevelGenerator").get_level_size()
	var map_overlay_size = $MapOverlay.size

	# Calculate the scaling factor based on the ratio of world size to map overlay size
	var scale_factor_x = (map_overlay_size.x / level_size.x) / 64
	var scale_factor_y = (map_overlay_size.y / level_size.y) / 64
	
	# Use the smaller of the two scale factors to ensure the world fits within the map overlay
	var map_scale = min(scale_factor_x, scale_factor_y)
	level_representation.set_map_scale(map_scale)
	level_representation.set_world_size(level_size)
	level_representation.set_map_size(map_overlay.size)
	
	level_representation.position = (map_overlay_size - (level_size * map_scale)) / 3

func toggle():
	map_overlay.visible = !map_overlay.visible
