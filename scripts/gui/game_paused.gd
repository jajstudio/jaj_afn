extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	self.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		self.show()
		if Global.game_running == true and Global.is_multiplayer == false:
			self.global_position = Global.player_position
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Global.game_running = false
			get_tree().paused = true
			self.show()
		elif Global.game_running == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			Global.game_running = true
			get_tree().paused = false
			self.hide()

func _on_resume_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.game_running = true
	get_tree().paused = false
	self.hide()

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_exit_to_main_menu_pressed() -> void:
	Global.game_running = false
	Global.is_multiplayer = false
	Global.game_controller.change_game_scene("res://scenes/empty_game_scene.tscn")
	Global.game_controller.change_gui_scene("res://scenes/menus/main_menu.tscn")
	get_tree().paused = false
	
func _on_exit_game_pressed() -> void:
	get_tree().quit()
