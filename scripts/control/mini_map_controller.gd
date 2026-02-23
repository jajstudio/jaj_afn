extends Control
class_name MiniMapController

@onready var frame: TextureRect = $CenterContainer/MiniMapBackground/CenterContainer/MiniMapFrame
@onready var viewport: SubViewport = $CenterContainer/MiniMapBackground/CenterContainer/MiniMapFrame/MiniMapViewport
@onready var root: Node2D = $CenterContainer/MiniMapBackground/CenterContainer/MiniMapFrame/MiniMapViewport/MiniMapRoot
@onready var player_dot: ColorRect = $CenterContainer/MiniMapBackground/PlayerDot

const WORLD_CHUNK_SIZE := 6
const MINIMAP_CHUNK_SIZE := 6
const MINIMAP_VIEW_RADIUS := 10

var minimap_chunks := {}   # Visible chunk sprites for small map
var minimap_data := {}     # Persistent explored tiles: Dictionary<Vector2i, PackedColorArray>
var current_player_chunk := Vector2i.ZERO

var TILE_COLORS := {
	"sand": Color(0.9, 0.85, 0.55),
	"grass": Color(0.2, 0.8, 0.2),
	"water": Color(0.1, 0.3, 0.8),
	"stone": Color(0.5, 0.5, 0.5),
}

class MinimapChunk:
	var chunk_pos: Vector2i
	var image: Image
	var texture: ImageTexture
	var sprite: Sprite2D
	var dirty := false

# ---------------- READY ----------------
func _ready():
	viewport.transparent_bg = true
	frame.texture = viewport.get_texture()

# ---------------- PROCESS ----------------
func _process(_delta):
	for chunk in minimap_chunks.values():
		if chunk.dirty:
			chunk.texture.update(chunk.image)
			chunk.dirty = false

# ---------------- SMALL MAP ----------------
func _get_player_minimap_pos(world_tile_pos: Vector2i) -> Vector2:
	return (Vector2(world_tile_pos) / WORLD_CHUNK_SIZE) * MINIMAP_CHUNK_SIZE

func _create_chunk(chunk_pos: Vector2i) -> MinimapChunk:
	var chunk := MinimapChunk.new()
	chunk.chunk_pos = chunk_pos

	chunk.image = Image.create(
		MINIMAP_CHUNK_SIZE,
		MINIMAP_CHUNK_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	chunk.image.fill(Color(0,0,0,0))

	# Fill from persistent data
	if minimap_data.has(chunk_pos):
		var data: PackedColorArray = minimap_data[chunk_pos]
		for y in range(WORLD_CHUNK_SIZE):
			for x in range(WORLD_CHUNK_SIZE):
				chunk.image.set_pixel(x, y, data[y * WORLD_CHUNK_SIZE + x])

	chunk.texture = ImageTexture.create_from_image(chunk.image)
	chunk.sprite = Sprite2D.new()
	chunk.sprite.texture = chunk.texture
	chunk.sprite.position = chunk_pos * MINIMAP_CHUNK_SIZE
	return chunk

func _get_or_create_chunk(chunk_pos: Vector2i) -> MinimapChunk:
	if minimap_chunks.has(chunk_pos):
		return minimap_chunks[chunk_pos]

	var chunk := _create_chunk(chunk_pos)
	minimap_chunks[chunk_pos] = chunk
	root.add_child(chunk.sprite)
	return chunk

func paint_tile(world_tile_pos: Vector2i, tile_type: String) -> void:
	var chunk_pos := Vector2i(
		floori(float(world_tile_pos.x) / WORLD_CHUNK_SIZE),
		floori(float(world_tile_pos.y) / WORLD_CHUNK_SIZE)
	)
	var local := Vector2i(posmod(world_tile_pos.x, WORLD_CHUNK_SIZE), posmod(world_tile_pos.y, WORLD_CHUNK_SIZE))

	# --- Persistent data ---
	if not minimap_data.has(chunk_pos):
		minimap_data[chunk_pos] = PackedColorArray()
		for i in range(WORLD_CHUNK_SIZE * WORLD_CHUNK_SIZE):
			minimap_data[chunk_pos].append(Color(0,0,0,0))

	minimap_data[chunk_pos][local.y * WORLD_CHUNK_SIZE + local.x] = TILE_COLORS.get(tile_type, Color.MAGENTA)

	# --- Update visible chunk ---
	var chunk := _get_or_create_chunk(chunk_pos)
	chunk.image.set_pixel(local.x, local.y, TILE_COLORS.get(tile_type, Color.MAGENTA))
	chunk.dirty = true

func update_player_position(world_tile_pos: Vector2i) -> void:
	var new_chunk := Vector2i(
		floori(world_tile_pos.x / WORLD_CHUNK_SIZE),
		floori(world_tile_pos.y / WORLD_CHUNK_SIZE)
	)
	if new_chunk != current_player_chunk:
		current_player_chunk = new_chunk
		_update_visible_chunks()
	_center_minimap_on_player(world_tile_pos)

func _center_minimap_on_player(world_tile_pos: Vector2i) -> void:
	var player_pos_px := _get_player_minimap_pos(world_tile_pos)
	var frame_center: Vector2 = frame.texture.get_size() / 2
	root.position = frame_center - player_pos_px
	#player_dot.position = frame_center

func _update_visible_chunks() -> void:
	var keep := {}
	for x in range(-MINIMAP_VIEW_RADIUS - 2, MINIMAP_VIEW_RADIUS + 2):
		for y in range(-MINIMAP_VIEW_RADIUS - 2, MINIMAP_VIEW_RADIUS + 2):
			var pos := current_player_chunk + Vector2i(x, y)
			keep[pos] = true
			_get_or_create_chunk(pos)

	for pos in minimap_chunks.keys():
		if not keep.has(pos):
			_unload_chunk(pos)

func _unload_chunk(chunk_pos: Vector2i) -> void:
	var chunk: MinimapChunk = minimap_chunks[chunk_pos]
	chunk.sprite.queue_free()
	chunk.image = null
	chunk.texture = null
	minimap_chunks.erase(chunk_pos)

# ---------------- FULL MAP ----------------
var full_map_sprite: Sprite2D = null
var full_map_bounds_min := Vector2i.ZERO
var full_map_bounds_max := Vector2i.ZERO

func open_full_map():
	
	# Remove small map sprites
	for chunk in minimap_chunks.values():
		chunk.sprite.queue_free()
	minimap_chunks.clear()

	# Compute full map bounds
	full_map_bounds_min = Vector2i(2147483647, 2147483647)
	full_map_bounds_max = Vector2i(-2147483648, -2147483648)
	
	for chunk_pos in minimap_data.keys():
		full_map_bounds_min.x = min(full_map_bounds_min.x, chunk_pos.x)
		full_map_bounds_min.y = min(full_map_bounds_min.y, chunk_pos.y)
		full_map_bounds_max.x = max(full_map_bounds_max.x, chunk_pos.x)
		full_map_bounds_max.y = max(full_map_bounds_max.y, chunk_pos.y)

	var map_width = (full_map_bounds_max.x - full_map_bounds_min.x + 1) * WORLD_CHUNK_SIZE
	var map_height = (full_map_bounds_max.y - full_map_bounds_min.y + 1) * WORLD_CHUNK_SIZE

	# Create big image
	var big_image = Image.create(map_width, map_height, false, Image.FORMAT_RGBA8)
	big_image.fill(Color(0,0,0,0))

	# Copy all chunk data into big image
	for chunk_pos in minimap_data.keys():
		var data: PackedColorArray = minimap_data[chunk_pos]
		for y in range(WORLD_CHUNK_SIZE):
			for x in range(WORLD_CHUNK_SIZE):
				var color = data[y * WORLD_CHUNK_SIZE + x]
				var global_x = (chunk_pos.x - full_map_bounds_min.x) * WORLD_CHUNK_SIZE + x
				var global_y = (chunk_pos.y - full_map_bounds_min.y) * WORLD_CHUNK_SIZE + y
				big_image.set_pixel(global_x, global_y, color)

	# Create texture
	var big_texture = ImageTexture.create_from_image(big_image)

	# Display single sprite
	if full_map_sprite:
		full_map_sprite.queue_free()
	full_map_sprite = Sprite2D.new()
	full_map_sprite.texture = big_texture
	full_map_sprite.position = Vector2.ZERO
	root.add_child(full_map_sprite)

	# Scale for zoom out
	#root.scale = Vector2(2,2)

func close_full_map():
	# Remove full map sprite
	if full_map_sprite:
		full_map_sprite.queue_free()
		full_map_sprite = null
	root.scale = Vector2(1,1)
	_update_visible_chunks()

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
