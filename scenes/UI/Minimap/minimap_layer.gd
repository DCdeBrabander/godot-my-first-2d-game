extends CanvasLayer

@onready var map_overlay = $MapOverlay
@onready var map = $MapOverlay/Minimap

func _ready():
	Signals.level_updated.connect(update_map)
	map_overlay.visible = false

func update_map(level_data: Dictionary):
	Signals.map_updating.emit()
	map.remove_all_markers()
	
	var level_size = level_data["bounding_box"].size
	var map_overlay_size = $MapOverlay.size
	
	# Calculate the scaling factor based on the ratio of world size to map overlay size
	var scale_factor_x = (map_overlay_size.x / level_size.x) / 64
	var scale_factor_y = (map_overlay_size.y / level_size.y) / 64
	
	# Use the smaller of the two scale factors to ensure the world fits within the map overlay
	var map_scale = min(scale_factor_x, scale_factor_y)
	
	map.set_map_scale(map_scale).set_world_size(level_size).set_map_size(map_overlay.size)
	map.position = (map_overlay_size - (level_size * map_scale)) / 2
	
	map.set_level_data(level_data).draw_map()
	
	for player in Global.get_players():
		map.add_marker_for_node(player.get_instance_id())
		
	Signals.map_updated.emit()

func toggle():
	map_overlay.visible = !map_overlay.visible
