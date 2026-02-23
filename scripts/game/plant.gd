extends Node2D

var tile_pos: Vector2i  # This "mailbox" must exist for the assignment to work!

@onready var one_tile_plant: Sprite2D = $OneTilePlants
@onready var two_tile_plant: Sprite2D = $TwoTilePlants
@onready var two_tile_plant_reflection: Sprite2D = $TwoTilePlants/TwoTilePlantsReflection

const ONE_TILE_PLANT_REGIONS = {
	"forest_plant_1": Rect2(112, 3, 15, 13),
	"forest_plant_2": Rect2(129, 3, 13, 13),
	"forest_plant_3": Rect2(145, 2.5, 12, 13),
	"forest_plant_4": Rect2(161, 2.5, 11, 13),
	"forest_plant_5": Rect2(176, 2, 18, 13),
	"forest_mushroom_1": Rect2(159.5, 19, 15, 13),
	"forest_mushroom_2": Rect2(174, 20, 12, 12),
}
const TWO_TILE_PLANT_REGIONS = {
	"forest_pond_reed_1": Rect2(209, 4, 11, 28),
	"forest_pond_reed_2": Rect2(228, 4, 11, 28),
	"forest_pond_reed_3": Rect2(240, 0, 14, 32),
}

func set_plant_type(type_name: String):
	if ONE_TILE_PLANT_REGIONS.has(type_name):
		two_tile_plant.hide()
		one_tile_plant.region_enabled = true
		one_tile_plant.region_rect = ONE_TILE_PLANT_REGIONS[type_name]
	elif TWO_TILE_PLANT_REGIONS.has(type_name):
		one_tile_plant.hide()
		two_tile_plant.region_enabled = true
		two_tile_plant.region_rect = TWO_TILE_PLANT_REGIONS[type_name]
		two_tile_plant_reflection.region_enabled = true
		two_tile_plant_reflection.region_rect = TWO_TILE_PLANT_REGIONS[type_name]
		
