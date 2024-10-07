extends Control

@export var map_color: Color = Color(0.3, 0.3, 0.3)
@export var map_scale: float = 1
@export var map_tile_size = Vector2(2, 2)

var level_generator: Node
var world_size
var map_size
var updatable_referenced_nodes: Dictionary = {}
	
func _process(delta: float) -> void:
	update_reference_nodes_on_map()
		
# Function to set the level generator reference from the Main scene
func set_level_generator(generator: Node) -> void:
	level_generator = generator
	draw_level_representation()

# Draws the generated level on the minimap
func draw_level_representation():
	if level_generator == null:
		print("LevelGenerator not set!")
		return
		
	for child in get_children():
		child.queue_free()
	
	var tiles = level_generator.get_level_data()
	
	if tiles.has("floor"):
		for floor_tile_position in tiles["floor"].keys():
			var minimap_tile = ColorRect.new()
			minimap_tile.size = map_tile_size
			minimap_tile.position = floor_tile_position * 64 * map_scale
			minimap_tile.color = map_color
			add_child(minimap_tile)
		
func add_reference(updatable_reference_node: Node):
	if not updatable_reference_node or get_reference_key_for_node(updatable_reference_node) in updatable_referenced_nodes:
		return

	var marker = TextureRect.new()
	
	# Read the style from the reference node if it exists
	if updatable_reference_node.has_method("get_minimap_indicator_style"):
		var style = updatable_reference_node.get_minimap_indicator_style()
		marker.set_size(style.size)
		marker.texture = style.texture
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	else:
		marker.set_size(Vector2(8, 8))
		marker.texture = null
		marker.color = Color(0, 0, 1)

	add_child(marker)
	updatable_referenced_nodes[get_reference_key_for_node(updatable_reference_node)] = marker
	
func update_reference_nodes_on_map():
	for node_path in updatable_referenced_nodes.keys():
		var marker = updatable_referenced_nodes[node_path]
		var referenced_node: Node = get_node(node_path)
		
		if referenced_node:
			# Calculate the marker's position scaled to the minimap
			var normalized_x = (referenced_node.position.x * map_scale)
			var normalized_y = (referenced_node.position.y * map_scale)
			marker.position = Vector2(normalized_x, normalized_y)

func remove_reference(updatable_reference_node: Node):
	var reference_key = get_reference_key_for_node(updatable_reference_node)
	if reference_key in updatable_referenced_nodes:
		var indicator = updatable_referenced_nodes[reference_key]
		indicator.queue_free()
		updatable_referenced_nodes.erase(reference_key)

func get_reference_key_for_node(reference_node: Node) -> String:
	return reference_node.get_path()

func set_world_size(_world_size):
	world_size = _world_size

func set_map_size(_map_size):
	map_size = _map_size

func set_map_scale(scale: float):
	map_scale = scale
