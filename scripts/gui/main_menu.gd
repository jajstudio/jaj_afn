extends Control

func _ready() -> void:
	self.show()

func _process(_delta):
	pass

func _on_single_player_pressed() -> void:
	#Global.game_controller.change_gui_scene("res://scenes/game_paused.tscn")
	#Global.game_controller.change_game_scene("res://scenes/game.tscn")
	Global.game_controller.change_gui_scene("res://scenes/menus/select_character.tscn")
	#Global.game_running = true
	Global.is_multiplayer = false
	self.hide()
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _on_host_pressed() -> void:
	pass # Replace with function body.

func _on_join_pressed() -> void:
	pass # Replace with function body.

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
