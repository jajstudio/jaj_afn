extends Node2D

@export var leaf_scene: PackedScene
@export var atlas_texture: Texture2D
@export var tree_type: TREE_TYPE

@onready var tree_sprite := $Tree

var tile_pos: Vector2i  # This "mailbox" must exist for the assignment to work!
var player: Node2D

const LEAF_SPAWN_DISTANCE := 300.0

enum TREE_TYPE {
	OAK_LARGE_1,
	OAK_LARGE_2,
	DEAD
}

const TREE_REGIONS := {
	TREE_TYPE.OAK_LARGE_1:  Rect2i(0, 0, 80, 81),
	TREE_TYPE.OAK_LARGE_2:  Rect2i(0, 0, 80, 81),
}

const TREE_SHADOW_REGIONS := {
	TREE_TYPE.OAK_LARGE_1:  Rect2i(0, 0, 80, 81),
	TREE_TYPE.OAK_LARGE_2:  Rect2i(0, 0, 80, 81),
}

func _ready():
	tree_sprite.texture = atlas_texture
	tree_sprite.region_enabled = true
	tree_sprite.region_rect = TREE_REGIONS[tree_type]
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

	if TREE_REGIONS.has(tree_type):
		tree_sprite.region_rect = TREE_REGIONS[tree_type]
	else:
		push_error("Missing TREE_REGIONS for tree type %s" % tree_type)

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
