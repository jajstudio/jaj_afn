extends TextureRect

# --- Constants ---
const TILE_SIZE = 16
const CHUNK_TILES = 128
const CHUNK_PIXEL_SIZE = 128

const MINIMAP_SIZE = 100      # size when in corner minimap mode
const FULLMAP_SIZE = 700      # size when opened fullscreen

const TILE_COLORS = {
	"grass":  Color(0.2, 0.6, 0.2),
	"water":  Color(0.1, 0.3, 0.8),
	"sand":   Color(0.9, 0.8, 0.5),
	"stone":  Color(0.5, 0.5, 0.5),
	"forest": Color(0.1, 0.4, 0.1),
}

# --- State ---
var minimap_chunks: Dictionary = {}
var is_fullmap_open: bool = false

# Panning
var is_dragging: bool = false
var drag_start_mouse: Vector2
var drag_start_origin: Vector2

# The top-left tile coord the display is showing
# In minimap mode this stays fixed, in fullmap mode the player can pan it
var minimap_origin: Vector2 = Vector2(0, 0)   # locked, follows nothing (fixed overview)
var fullmap_origin: Vector2 = Vector2(0, 0)   # player can drag this around

# Zoom (fullmap only)
var zoom: float = 1.0
const ZOOM_MIN = 0.25
const ZOOM_MAX = 8.0
const ZOOM_STEP = 0.15

@onready var player_dot = $"../PlayerDot"
@onready var player = get_tree().get_first_node_in_group("player")

# --- Setup ---
func _ready():
	custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_STOP  # needed to receive mouse events

	var base_image = Image.create(MINIMAP_SIZE, MINIMAP_SIZE, false, Image.FORMAT_RGBA8)
	base_image.fill(Color.BLACK)
	texture = ImageTexture.create_from_image(base_image)
	player_dot.set_deferred("size", Vector2(4, 4))

# --- Input ---
func _gui_input(event: InputEvent):
	# Toggle fullmap with M
	if event is InputEventKey and event.keycode == KEY_M and event.pressed and not event.echo:
		_toggle_fullmap()
	
	if is_fullmap_open:
		# Drag to pan
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed and get_rect().has_point(get_local_mouse_position()):
					is_dragging = true
					drag_start_mouse = get_global_mouse_position()
					drag_start_origin = fullmap_origin
				else:
					is_dragging = false
			
			# Scroll to zoom
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = clamp(zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clamp(zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		
		if event is InputEventMouseMotion and is_dragging:
			var delta = get_global_mouse_position() - drag_start_mouse
			# Divide by zoom so dragging feels consistent at all zoom levels
			fullmap_origin = drag_start_origin - delta / zoom

func _toggle_fullmap():
	is_fullmap_open = !is_fullmap_open
	if is_fullmap_open:
		# Center the full map on the player when opening
		var player_tile = player.global_position / TILE_SIZE
		fullmap_origin = player_tile - Vector2(FULLMAP_SIZE, FULLMAP_SIZE) / 2.0 / zoom
		custom_minimum_size = Vector2(FULLMAP_SIZE, FULLMAP_SIZE)
		# Center it on screen
		set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	else:
		custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
		# Put it back in the top-right corner
		set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		zoom = 1.0

# --- Painting ---
func paint_tile(tile_world_x: int, tile_world_y: int, tile_type: String):
	var chunk_coord = Vector2i(
		floori(float(tile_world_x) / CHUNK_TILES),
		floori(float(tile_world_y) / CHUNK_TILES)
	)
	if not minimap_chunks.has(chunk_coord):
		_create_chunk(chunk_coord)

	var local_x = ((tile_world_x % CHUNK_TILES) + CHUNK_TILES) % CHUNK_TILES
	var local_y = ((tile_world_y % CHUNK_TILES) + CHUNK_TILES) % CHUNK_TILES

	var color = TILE_COLORS.get(tile_type, Color.MAGENTA)
	minimap_chunks[chunk_coord].image.set_pixel(local_x, local_y, color)
	minimap_chunks[chunk_coord].dirty = true

func _create_chunk(chunk_coord: Vector2i):
	var img = Image.create(CHUNK_PIXEL_SIZE, CHUNK_PIXEL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	minimap_chunks[chunk_coord] = {
		"image": img,
		"texture": ImageTexture.create_from_image(img),
		"dirty": false
	}

# --- Rendering ---
func _process(_delta):
	_flush_dirty_chunks()
	_redraw_display()
	_update_player_dot()

func _flush_dirty_chunks():
	for chunk_coord in minimap_chunks:
		var chunk = minimap_chunks[chunk_coord]
		if chunk.dirty:
			chunk.texture.update(chunk.image)
			chunk.dirty = false

func _redraw_display():
	var display_size = FULLMAP_SIZE if is_fullmap_open else MINIMAP_SIZE
	var origin = fullmap_origin if is_fullmap_open else minimap_origin

	var display_image = Image.create(display_size, display_size, false, Image.FORMAT_RGBA8)
	display_image.fill(Color.BLACK)

	# How many tiles fit in the display at current zoom
	var tiles_in_view = Vector2(display_size, display_size) / zoom

	var chunk_min = Vector2i(
		floori(origin.x / CHUNK_TILES),
		floori(origin.y / CHUNK_TILES)
	)
	var chunk_max = Vector2i(
		floori((origin.x + tiles_in_view.x) / CHUNK_TILES),
		floori((origin.y + tiles_in_view.y) / CHUNK_TILES)
	)

	for cx in range(chunk_min.x, chunk_max.x + 1):
		for cy in range(chunk_min.y, chunk_max.y + 1):
			var coord = Vector2i(cx, cy)
			if not minimap_chunks.has(coord):
				continue

			var chunk_tile_origin = Vector2(cx * CHUNK_TILES, cy * CHUNK_TILES)

			# Where on the display does this chunk's top-left land?
			var blit_pos = (chunk_tile_origin - origin) * zoom

			# How large is the chunk image scaled at current zoom?
			var scaled_size = int(CHUNK_PIXEL_SIZE * zoom)
			if scaled_size < 1:
				scaled_size = 1

			# Scale the chunk image to match zoom level
			var scaled_img = minimap_chunks[coord].image.duplicate()
			scaled_img.resize(scaled_size, scaled_size, Image.INTERPOLATE_NEAREST)

			# Clip to display bounds
			var src_x = 0
			var src_y = 0
			var dst_x = int(blit_pos.x)
			var dst_y = int(blit_pos.y)

			if dst_x < 0:
				src_x = -dst_x
				dst_x = 0
			if dst_y < 0:
				src_y = -dst_y
				dst_y = 0

			var blit_w = min(scaled_size - src_x, display_size - dst_x)
			var blit_h = min(scaled_size - src_y, display_size - dst_y)

			if blit_w > 0 and blit_h > 0:
				display_image.blit_rect(
					scaled_img,
					Rect2i(src_x, src_y, blit_w, blit_h),
					Vector2i(dst_x, dst_y)
				)

	texture.update(display_image)

func _update_player_dot():
	if not player:
		return

	var display_size = FULLMAP_SIZE if is_fullmap_open else MINIMAP_SIZE
	var origin = fullmap_origin if is_fullmap_open else minimap_origin
	var tile_pos = player.global_position / TILE_SIZE

	# Convert world tile pos to display pixel pos
	var dot_pos = (tile_pos - origin) * zoom
	player_dot.position = dot_pos - player_dot.size / 2.0

	# Hide the dot if it's outside the map display
	player_dot.visible = Rect2(Vector2.ZERO, Vector2(display_size, display_size)).has_point(dot_pos)
