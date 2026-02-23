extends TextureRect

const TILE_SIZE = 16
const MAP_SIZE = 512      # minimap image resolution (covers 256 tiles in each direction from origin)
const DISPLAY_SIZE = 150  # how large the minimap appears on screen in pixels

const TILE_COLORS = {
	"grass": Color(0.2, 0.6, 0.2),
	"water": Color(0.1, 0.3, 0.8),
	"sand":  Color(0.9, 0.8, 0.5),
	"stone": Color(0.5, 0.5, 0.5),
}

var image: Image
var map_texture: ImageTexture
var dirty: bool = false

@onready var player_dot = $"../PlayerDot"  # adjust path to match your scene tree
@onready var player = get_tree().get_first_node_in_group("Player")

func _ready():
	# Set the TextureRect display size
	custom_minimum_size = Vector2(DISPLAY_SIZE, DISPLAY_SIZE)
	
	# Create the image, filled black (unexplored)
	image = Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	
	map_texture = ImageTexture.create_from_image(image)
	texture = map_texture
	
	# Make sure the texture stretches to fill the TextureRect
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE

func paint_tile(tile_world_x: int, tile_world_y: int, tile_type: String):
	# World tile coords → minimap pixel, with (0,0) at image center
	var px = (MAP_SIZE / 2) + tile_world_x
	var py = (MAP_SIZE / 2) + tile_world_y
	
	if px < 0 or py < 0 or px >= MAP_SIZE or py >= MAP_SIZE:
		return
	
	var color = TILE_COLORS.get(tile_type, Color.MAGENTA)
	image.set_pixel(px, py, color)
	dirty = true

func _process(_delta):
	if dirty:
		map_texture.update(image)
		dirty = false
	
	_update_player_dot()

func _update_player_dot():
	if not player:
		return
	
	# Convert player pixel position → tile position
	var tile_pos = (player.global_position / TILE_SIZE).floor()
	
	# Map that to where it sits within the displayed minimap widget
	var map_center = Vector2(DISPLAY_SIZE, DISPLAY_SIZE) / 2.0
	player_dot.position = map_center + tile_pos - player_dot.size / 2.0
