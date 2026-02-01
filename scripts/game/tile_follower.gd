# Indicator.gd
extends Sprite2D

@export var player: Node2D 
@export var tilemap: TileMap 

const GRID_SIZE = 16 

func _process(_delta):
	var mouse_global_pos = get_global_mouse_position()

	position = Vector2((round(mouse_global_pos.x / GRID_SIZE) * GRID_SIZE) + 8, \
					   (round(mouse_global_pos.y / GRID_SIZE) * GRID_SIZE) + 8) 

func get_hovered_tile_coords() -> Vector2i:
	if tilemap:
		return tilemap.local_to_map(position)
	return Vector2i.ZERO
