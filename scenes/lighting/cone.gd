extends Light2D

# Cone settings
@export var cone_angle: float = 60.0  
@export var cone_length: float = 400.0
@export var cone_opacity: float = 0.2

func _ready() -> void:
	# Initialize the light cone when the node is ready
	print("light ready!")
	
	
# Function to create a cone-shaped texture procedurally
func create_cone_texture() -> ImageTexture:
	var img = Image.new()
	var texture_size = Vector2(512, 512)  # Set the texture size
	img.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	img.lock()

	# Draw a cone shape programmatically (simplified)
	var center = Vector2(texture_size.x / 2, texture_size.y)  # Bottom center of the image
	var angle_step = deg_to_rad(cone_angle) / 2.0

	for y in range(texture_size.y):
		var line_length = (y / texture_size.y) * (texture_size.x / 2) * tan(angle_step)
		var start_x = center.x - line_length
		var end_x = center.x + line_length

		for x in range(start_x, end_x):
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))  # White pixel

	img.unlock()

	# Convert image to texture
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	return texture

func create_light_cone() -> void:
	# Set light properties
	self.energy = cone_opacity  # Set light intensity (similar to opacity)
	self.range = cone_length  # Set the range (length) of the light cone

	# Configure the light texture to simulate a cone shape programmatically
	var light_texture = create_cone_texture()
	self.texture = light_texture
	self.offset = Vector2.ZERO  # Set offset if needed

	# Enable shadow casting
	self.shadow_enabled = true
	self.shadow_filter = Light2D.SHADOW_FILTER_PCF13  # Set shadow filtering for smooth shadows

	
func create_light_cone_vertices() -> void:
	# Convert the angle to radians for calculation
	var angle_radians = deg_to_rad(cone_angle)

	# Define the vertices for the cone shape
	var vertices = [
		Vector2.ZERO,  # Origin point at the player/character position
		Vector2(cone_length * cos(-angle_radians / 2), cone_length * sin(-angle_radians / 2)),  # Left side
		Vector2(cone_length * cos(angle_radians / 2), cone_length * sin(angle_radians / 2)),   # Right side
	]

	# Set the vertices for the light cone
	self.polygon = vertices

	# Set the color with the specified opacity
	self.color = Color(1.0, 1.0, 1.0, cone_opacity)  # White with transparency

	# Create a material and set blend mode to add
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	self.material = material  # Assign the material to the Polygon2D
	
func update(position: Vector2, direction: Vector2):
	self.position = position
	self.rotation = direction.angle()
