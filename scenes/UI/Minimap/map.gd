extends Control

@export var map_color: Color = Color(0.5, 0.5, 0.5)
@export var map_scale: float = 1
@export var map_tile_size = Vector2(10, 10)

@onready var BasicMarker = $Markers/BasicMarker
@onready var TextureMarker = $Markers/TextureMarker

enum MarkerTypes {
	BASIC,
	TEXTURE
}

var node_markers: Dictionary = {}
var level_generator: Node
var level_data
var world_size
var map_size
	
func _process(delta: float) -> void:
	update_markers_on_map()

# Draws the generated level on the minimap
func draw_map():
	if level_data == null:
		print("Level data not set!")
		return
		
	for child in get_children():
		child.queue_free()
	
	self.position = Vector2.ZERO
	
	if level_data.has("floor"):
		for floor_tile_position in level_data["floor"].keys():
			var minimap_tile = ColorRect.new()
			minimap_tile.size = map_tile_size
			minimap_tile.position = floor_tile_position * map_scale * 64 # abstract / normalize tile_size (64
			minimap_tile.color = map_color
			add_child(minimap_tile)
	
	if level_data.has("rooms"):
		for room_rect: Rect2 in level_data["rooms"]:
			var room_tile = ColorRect.new()
			room_tile.size = room_rect.size * 1.1
			room_tile.position = room_rect.position * map_scale * 64 # abstract / normalize tile_size (64
			room_tile.color = Color(1, 1, 1)
			add_child(room_tile)
		
func add_marker_for_node(reference_node: Node2D, marker_type: MarkerTypes = MarkerTypes.BASIC):
	if not reference_node or get_reference_key_for_node(reference_node) in node_markers:
		return
	
	var marker = null
	
	match (marker_type):
		MarkerTypes.BASIC: 
			marker = BasicMarker.duplicate()
		MarkerTypes.TEXTURE: 
			marker = TextureMarker.duplicate()
		_: 
			print("Unknown marker type: %s" % marker_type)
			return
	
	if (reference_node.has_method("get_minimap_indicator_style")):
		var marker_style = reference_node.get_minimap_indicator_style()
		marker.set_color(marker_style.color)
		if (marker_style.has("animate")):
			marker.set_animation(marker_style["animate"])

	node_markers[get_reference_key_for_node(reference_node)] = marker
	add_child(marker)

# very naively always update on each frame
func update_markers_on_map():
	for node_path in node_markers.keys():
		var marker = node_markers[node_path]
		var referenced_node: Node = get_node(node_path)
				
		if referenced_node:
			# Calculate the marker's position scaled to the minimap
			var normalized_x = (referenced_node.position.x * map_scale)
			var normalized_y = (referenced_node.position.y * map_scale)
			marker.position = Vector2(normalized_x, normalized_y)

func remove_reference(reference_node: Node):
	var reference_key = get_reference_key_for_node(reference_node)
	if reference_key in node_markers:
		var indicator = node_markers[reference_key]
		indicator.queue_free()
		node_markers.erase(reference_key)

func get_reference_key_for_node(reference_node: Node) -> String:
	return reference_node.get_path()

func set_world_size(_world_size):
	world_size = _world_size

func set_map_size(_map_size):
	map_size = _map_size

func set_map_scale(scale: float):
	map_scale = scale
	
func set_level_data(_data):
	level_data = _data
	draw_map()
