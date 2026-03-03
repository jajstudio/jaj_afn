extends Node2D

@export var leaf_scene: PackedScene
@export var atlas_texture: Texture2D
@export var atlas_texture_2: Texture2D
@export var tree_type: TREE_TYPE

@onready var tree_sprite := $Tree
@onready var shadow_sprite := $Tree/Shadow

var tile_pos: Vector2i  # This "mailbox" must exist for the assignment to work!
var player: Node2D

const LEAF_SPAWN_DISTANCE := 300.0

enum TREE_TYPE {
	OAK_LARGE_1,
	OAK_LARGE_2,
	PINE_LARGE_1,
	PINE_LARGE_2
}

# Used to mark sprite regions in the texture atlas
const TREE_REGIONS := {
	TREE_TYPE.OAK_LARGE_1:  Rect2i(0, 0, 80, 81),
	TREE_TYPE.OAK_LARGE_2:  Rect2i(88, 10, 66, 70),
	TREE_TYPE.PINE_LARGE_1: Rect2i(159, 0, 51, 80),
	TREE_TYPE.PINE_LARGE_2: Rect2i(223, 0, 51, 80),
}

# Used to arrange the y sort origin 
const TREE_OFFSETS := {
	TREE_TYPE.OAK_LARGE_1: Vector2(-42, -80),
	TREE_TYPE.OAK_LARGE_2: Vector2(-31, -69),
	TREE_TYPE.PINE_LARGE_1: Vector2(-24, -79),
	TREE_TYPE.PINE_LARGE_2: Vector2(-24, -79),   
}

#  Used in the shader parameter
const TREE_HEIGHT_OFFSETS := {
	TREE_TYPE.OAK_LARGE_1: 0.99,
	TREE_TYPE.OAK_LARGE_2: 0.98, 
	TREE_TYPE.PINE_LARGE_1: 0.99,
	TREE_TYPE.PINE_LARGE_2: 0.99,
}

# Used to mark shadow regions in the texture atlas
const TREE_SHADOW_REGIONS := {
	TREE_TYPE.OAK_LARGE_1:  Rect2i(0, 0, 80, 70),
	TREE_TYPE.OAK_LARGE_2:  Rect2i(87, 0, 65.5, 55),
	TREE_TYPE.PINE_LARGE_1:  Rect2i(159, 0, 49, 70),
	TREE_TYPE.PINE_LARGE_2:  Rect2i(159, 0, 49, 70),
}

func _ready():
	tree_sprite.texture = atlas_texture
	tree_sprite.region_enabled = true
	tree_sprite.region_rect = TREE_REGIONS[tree_type]
	shadow_sprite.texture = atlas_texture_2
	shadow_sprite.region_rect = TREE_SHADOW_REGIONS[tree_type]
	shadow_sprite.region_enabled = true
	_apply_tree_type()
	_schedule_next_batch()
	
func set_tree_type(type: TREE_TYPE) -> void:
	tree_type = type

	# If already in scene, apply immediately
	if is_inside_tree():
		_apply_tree_type()
		
func _apply_tree_type():
	tree_sprite.texture = atlas_texture
	tree_sprite.region_enabled = true
	if tree_sprite.material:
		tree_sprite.material = tree_sprite.material.duplicate()
	if TREE_REGIONS.has(tree_type):
		tree_sprite.region_rect = TREE_REGIONS[tree_type]
	if TREE_OFFSETS.has(tree_type):
		tree_sprite.offset = TREE_OFFSETS[tree_type]
	if TREE_SHADOW_REGIONS.has(tree_type):
		shadow_sprite.region_rect = TREE_SHADOW_REGIONS[tree_type]
	if tree_sprite.material is ShaderMaterial:
		var h_offset = TREE_HEIGHT_OFFSETS.get(tree_type, 0.99) # Default to 0.99
		tree_sprite.material.set_shader_parameter("heightOffset", h_offset)
	else:
		print('fail')

func _schedule_next_batch():
	await get_tree().create_timer(randf_range(4.0, 10.0)).timeout

	if not is_inside_tree():
		return

	if player == null:
		return

	if global_position.distance_to(player.global_position) > LEAF_SPAWN_DISTANCE:
		_schedule_next_batch()
		return

	for i in randi_range(0, 5):
		var leaf = leaf_scene.instantiate()
		leaf.position = Vector2(randf_range(-40, 40), -20)
		add_child(leaf)

	_schedule_next_batch()
