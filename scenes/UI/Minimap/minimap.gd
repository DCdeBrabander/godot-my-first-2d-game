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

func _ready() -> void:
	Signals.map_updating.connect(pause_process.bind(true))
	Signals.map_updated.connect(pause_process.bind(false))

func pause_process(is_paused):
	print("map updating paused? ", is_paused)
	set_process(is_paused)

func _physics_process(delta: float) -> void:
	update_markers_on_map()

func add_marker_for_node(instance_id: int, marker_type: MarkerTypes = MarkerTypes.BASIC):
	#var reference_node_instance_id = get_reference_key_for_node(reference_node)
	var marker = null
	
	var node = instance_from_id(instance_id)
	
	#if not reference_node_instance_id or reference_node_instance_id.length() == 	0:
		#print("INVALID NODE KEY", reference_node_instance_id, reference_node)
		#return
	
	if instance_id in node_markers:
		return
	
	match (marker_type):
		MarkerTypes.BASIC:
			marker = BasicMarker.duplicate(15)
		MarkerTypes.TEXTURE:
			marker = TextureMarker.duplicate(15)
		_: 
			print("Unknown marker type: %s" % marker_type)
			return
	
	if (node.has_method("get_minimap_indicator_style")):
		var marker_style = node.get_minimap_indicator_style()
		marker.set_color(marker_style.color)
		if (marker_style.has("animate")):
			marker.set_animation(marker_style["animate"])
	else:
		marker.set_color(Color(200, 200, 200))

	add_child(marker)
	node_markers[instance_id] = marker

# very naively always update on each frame
func update_markers_on_map():
	for instance_id in node_markers.keys():
		var marker = node_markers[instance_id]
		var referenced_node: Node = instance_from_id(instance_id)
		
		if not is_instance_valid(referenced_node):
			remove_reference(referenced_node)
			print("Not valid node")
			continue
		
		if not "position" in marker:
			remove_reference(referenced_node)
			print("Marker is missing position..")
			continue

		# Calculate the marker's position scaled to the minimap
		var normalized_x = (referenced_node.position.x * map_scale)
		var normalized_y = (referenced_node.position.y * map_scale)
		
		marker.position = Vector2(normalized_x, normalized_y)

# Draws the generated level on the minimap
# TODO: update to NOT use all these colorrects but instantly draw single shape per room or even 1 texture for the whole map
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

func remove_reference(reference_node: Node):
	var reference_key = get_reference_key_for_node(reference_node)
	if reference_key in node_markers:
		var indicator = node_markers[reference_key]
		if is_instance_valid(indicator):
			indicator.queue_free()
		node_markers.erase(reference_key)

func remove_all_markers():
	if not node_markers.size():
		return

	for index in node_markers:
		node_markers[index].queue_free()
		
func get_reference_key_for_node(reference_node: Node) -> int:
	return reference_node.get_instance_id() #reference_node.get_path()

func set_world_size(_world_size):
	world_size = _world_size
	return self

func set_map_size(_map_size):
	map_size = _map_size
	return self

func set_map_scale(scale: float):
	map_scale = scale
	return self
	
func set_level_data(_data):
	level_data = _data
	return self
