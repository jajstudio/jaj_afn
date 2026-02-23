extends Control
class_name MiniMapController

@onready var frame: TextureRect = $CenterContainer/MiniMapBackground/CenterContainer/MiniMapFrame
@onready var player_dot: ColorRect = $CenterContainer/MiniMapBackground/PlayerDot

# Constants
const WORLD_CHUNK_SIZE := 6
const MINIMAP_CHUNK_SIZE := 6

# Persistent data
var minimap_data := {}  # Dictionary<Vector2i, PackedColorArray>

# Single image & texture for the minimap
var minimap_image: Image
var minimap_texture: ImageTexture

# Full map sprite for when opening big map
var full_map_sprite: Sprite2D = null
var full_map_texture: ImageTexture = null

# Tile colors
var TILE_COLORS := {
	"sand": Color(0.9, 0.85, 0.55),
	"grass": Color(0.2, 0.8, 0.2),
	"water": Color(0.1, 0.3, 0.8),
	"stone": Color(0.5, 0.5, 0.5),
}

# ---------------- READY ----------------
func _ready():
	# Initialize a small starting image
	minimap_image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	minimap_image.fill(Color(0,0,0,0))
	minimap_texture = ImageTexture.create_from_image(minimap_image)
	frame.texture = minimap_texture

# ---------------- TILE PAINTING ----------------
func paint_tile(world_tile_pos: Vector2i, tile_type: String) -> void:
	# Determine which chunk & local position
	var chunk_pos = Vector2i(floori(float(world_tile_pos.x) / WORLD_CHUNK_SIZE),
							  floori(float(world_tile_pos.y) / WORLD_CHUNK_SIZE))
	var local = Vector2i(posmod(world_tile_pos.x, WORLD_CHUNK_SIZE), posmod(world_tile_pos.y, WORLD_CHUNK_SIZE))

	# Persistent storage
	if not minimap_data.has(chunk_pos):
		minimap_data[chunk_pos] = PackedColorArray()
		for i in range(WORLD_CHUNK_SIZE * WORLD_CHUNK_SIZE):
			minimap_data[chunk_pos].append(Color(0,0,0,0))
	minimap_data[chunk_pos][local.y * WORLD_CHUNK_SIZE + local.x] = TILE_COLORS.get(tile_type, Color.MAGENTA)

	# Update the minimap image
	var x = chunk_pos.x * WORLD_CHUNK_SIZE + local.x
	var y = chunk_pos.y * WORLD_CHUNK_SIZE + local.y

	# Expand image if needed
	if x >= minimap_image.get_width() or y >= minimap_image.get_height():
		var new_width = max(minimap_image.get_width(), x + 1)
		var new_height = max(minimap_image.get_height(), y + 1)
		var new_image = Image.create(new_width, new_height, false, Image.FORMAT_RGBA8)
		new_image.fill(Color(0,0,0,0))
		new_image.blit_rect(minimap_image, Rect2(0,0,minimap_image.get_width(),minimap_image.get_height()), Vector2.ZERO)
		minimap_image = new_image
		minimap_texture = ImageTexture.create_from_image(minimap_image)
		frame.texture = minimap_texture

	minimap_image.set_pixel(x, y, TILE_COLORS.get(tile_type, Color.MAGENTA))
	minimap_texture.update(minimap_image)

# ---------------- PLAYER DOT ----------------
func update_player_dot(world_tile_pos: Vector2i) -> void:
	var pos = Vector2(world_tile_pos.x, world_tile_pos.y) / WORLD_CHUNK_SIZE * MINIMAP_CHUNK_SIZE
	player_dot.position = pos

# ---------------- FULL MAP ----------------
func open_full_map():
	# Compute bounds of all explored tiles
	var min_pos = Vector2i(2147483647, 2147483647)
	var max_pos = Vector2i(-2147483648, -2147483648)
	for chunk_pos in minimap_data.keys():
		min_pos.x = min(min_pos.x, chunk_pos.x)
		min_pos.y = min(min_pos.y, chunk_pos.y)
		max_pos.x = max(max_pos.x, chunk_pos.x)
		max_pos.y = max(max_pos.y, chunk_pos.y)

	var width = (max_pos.x - min_pos.x + 1) * WORLD_CHUNK_SIZE
	var height = (max_pos.y - min_pos.y + 1) * WORLD_CHUNK_SIZE

	var big_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	big_image.fill(Color(0,0,0,0))

	# Copy all minimap_data into big image
	for chunk_pos in minimap_data.keys():
		var data: PackedColorArray = minimap_data[chunk_pos]
		for y in range(WORLD_CHUNK_SIZE):
			for x in range(WORLD_CHUNK_SIZE):
				var color = data[y * WORLD_CHUNK_SIZE + x]
				var global_x = (chunk_pos.x - min_pos.x) * WORLD_CHUNK_SIZE + x
				var global_y = (chunk_pos.y - min_pos.y) * WORLD_CHUNK_SIZE + y
				big_image.set_pixel(global_x, global_y, color)

	full_map_texture = ImageTexture.create_from_image(big_image)

	# Create or replace sprite
	if full_map_sprite:
		full_map_sprite.queue_free()
	full_map_sprite = Sprite2D.new()
	full_map_sprite.texture = full_map_texture
	full_map_sprite.position = Vector2.ZERO
	add_child(full_map_sprite)

	# Optionally scale down to fit screen
	var scale_x = frame.get_size().x / big_image.get_width()
	var scale_y = frame.get_size().y / big_image.get_height()
	full_map_sprite.scale = Vector2(scale_x, scale_y)

func close_full_map():
	if full_map_sprite:
		full_map_sprite.queue_free()
		full_map_sprite = null

# ---------------- SAVE / LOAD ----------------
func save_minimap(path: String = "user://minimap.save") -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(minimap_data)
	file.close()

func load_minimap(path: String = "user://minimap.save") -> void:
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	minimap_data = file.get_var()
	file.close()

	# Rebuild minimap_image from data
	minimap_image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	minimap_image.fill(Color(0,0,0,0))
	for chunk_pos in minimap_data.keys():
		var data: PackedColorArray = minimap_data[chunk_pos]
		for y in range(WORLD_CHUNK_SIZE):
			for x in range(WORLD_CHUNK_SIZE):
				var color = data[y * WORLD_CHUNK_SIZE + x]
				var px = chunk_pos.x * WORLD_CHUNK_SIZE + x
				var py = chunk_pos.y * WORLD_CHUNK_SIZE + y
				if px >= minimap_image.get_width() or py >= minimap_image.get_height():
					continue
				minimap_image.set_pixel(px, py, color)
	minimap_texture = ImageTexture.create_from_image(minimap_image)
	frame.texture = minimap_texture
