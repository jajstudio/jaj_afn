extends Node

var game_controller : GameController
var game_running : bool
var is_multiplayer : bool
var in_pause_menu : bool
var player_position : Vector2
var world_data : Dictionary
var preloaded_game_scene = preload("res://scenes/game.tscn")
@onready var screen_width = get_viewport().size.x
@onready var screen_height = get_viewport().size.y

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_multiplayer = false
	game_running = false
	in_pause_menu = false
	player_position = Vector2(0, 0) # Menus reference this for positioning in the world

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass
