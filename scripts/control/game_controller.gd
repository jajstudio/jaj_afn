class_name GameController extends Node

@export var game : Node2D
@export var gui : Control

var current_game_scene
var current_gui_scene

func _ready() -> void:
	Global.game_controller = self
	change_gui_scene("res://scenes/menus/main_menu.tscn")
	current_game_scene = null
	
func _process(_delta) -> void:
	pass

func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_gui_scene != null:
		if delete:
			current_gui_scene.queue_free()
		elif keep_running:
			current_gui_scene.visible = false
		else:
			gui.remove_child(current_gui_scene)
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_gui_scene = new

func change_game_scene(new_scene, delete: bool = true, keep_running: bool = false) -> void:
	if current_game_scene != null:
		if delete:
			current_game_scene.queue_free()
		elif keep_running:
			current_game_scene.visible = false
		else:
			game.remove_child(current_game_scene)

	var new_instance

	# Check if we were given a string path or a preloaded scene
	if new_scene is String:
		# If it's a string, load it from disk
		new_instance = load(new_scene).instantiate()
	elif new_scene is PackedScene:
		# If it's a PackedScene, just instantiate it
		new_instance = new_scene.instantiate()
		print('using preload')
	else:
		printerr("Invalid scene type passed to change_game_scene.")
		return

	game.add_child(new_instance)
	current_game_scene = new_instance
	
