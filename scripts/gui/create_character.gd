extends Control

#@onready var character_panel = $CenterContainer/VBoxContainer/CharacterEditor/CharacterPanel
@onready var skin_color_picker: ColorPickerButton = $CenterContainer/VBoxContainer/CharacterEditor/CenterContainer/CharacterAttributes/Skin/ColorPickerButton
@onready var hair_color_picker: ColorPickerButton = $CenterContainer/VBoxContainer/CharacterEditor/CenterContainer/CharacterAttributes/HairColor/HairColorButton
@onready var eye_color_picker: ColorPickerButton = $CenterContainer/VBoxContainer/CharacterEditor/CenterContainer/CharacterAttributes/Eyes/EyeColorButton
@onready var hover_sound_player = $HoverSoundPlayer
@onready var button_pressed_sound_player = $ButtonPressedSoundPlayer
@export var player: Node2D
var new_player_color = null

func _ready():
	skin_color_picker.color = Color(0, 0, 0, 0)
	hair_color_picker.color = Color(0, 0, 0, 0)
	eye_color_picker.color = Color(0, 0, 0, 0)
	
func _on_back_button_pressed() -> void:
	Global.game_controller.change_gui_scene("res://scenes/menus/select_character.tscn")

func _on_create_button_pressed() -> void:
	Global.game_controller.change_gui_scene("res://scenes/menus/select_world.tscn")

func _on_l_skin_button_mouse_entered() -> void:
	hover_sound_player.play()

func _on_l_skin_button_pressed() -> void:
	button_pressed_sound_player.play()
	
func _on_r_skin_button_pressed() -> void:
	button_pressed_sound_player.play()
	
func _on_r_skin_button_mouse_entered() -> void:
	hover_sound_player.play()

func _on_color_picker_button_picker_created():
	var color_picker: ColorPicker = skin_color_picker.get_picker()
	
	var popup: PopupPanel = color_picker.get_parent()
	
	color_picker.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	
	var style_texture = StyleBoxTexture.new()
	style_texture.texture = load("res://assets/images/ui/colorpickerbg.png")

	popup.add_theme_stylebox_override("panel", style_texture)
	
	var color_picker_texture = load("res://assets/images/ui/colorpicker.png") 
	color_picker.add_theme_icon_override("picker_cursor", color_picker_texture)
	
	color_picker.sliders_visible = false
	color_picker.hex_visible = false
	color_picker.presets_visible = false
	color_picker.sampler_visible = false
	color_picker.color_modes_visible = false
	
	color_picker.add_theme_constant_override("sv_width", 150)
	color_picker.add_theme_constant_override("sv_height", 150)

func _on_color_picker_button_color_changed(color: Color) -> void:
	new_player_color = color
	new_player_color.a = 1.0
	player.change_skin_color(new_player_color)


func _on_hair_color_button_color_changed(color: Color) -> void:
	new_player_color = color
	new_player_color.a = 1.0
	player.change_hair_color(new_player_color)


func _on_hair_color_button_picker_created() -> void:
	var color_picker: ColorPicker = hair_color_picker.get_picker()
	
	var popup: PopupPanel = color_picker.get_parent()
	
	color_picker.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	
	var style_texture = StyleBoxTexture.new()
	style_texture.texture = load("res://assets/images/ui/colorpickerbg.png")

	popup.add_theme_stylebox_override("panel", style_texture)
	
	var color_picker_texture = load("res://assets/images/ui/colorpicker.png") 
	color_picker.add_theme_icon_override("picker_cursor", color_picker_texture)
	
	color_picker.sliders_visible = false
	color_picker.hex_visible = false
	color_picker.presets_visible = false
	color_picker.sampler_visible = false
	color_picker.color_modes_visible = false
	
	color_picker.add_theme_constant_override("sv_width", 150)
	color_picker.add_theme_constant_override("sv_height", 150)

func _on_eye_color_button_color_changed(color: Color) -> void:
	new_player_color = color
	new_player_color.a = 1.0
	player.change_eye_color(new_player_color)


func _on_eye_color_button_picker_created() -> void:
	var color_picker: ColorPicker = eye_color_picker.get_picker()
	
	var popup: PopupPanel = color_picker.get_parent()
	
	color_picker.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	
	var style_texture = StyleBoxTexture.new()
	style_texture.texture = load("res://assets/images/ui/colorpickerbg.png")

	popup.add_theme_stylebox_override("panel", style_texture)
	
	var color_picker_texture = load("res://assets/images/ui/colorpicker.png") 
	color_picker.add_theme_icon_override("picker_cursor", color_picker_texture)
	
	color_picker.sliders_visible = false
	color_picker.hex_visible = false
	color_picker.presets_visible = false
	color_picker.sampler_visible = false
	color_picker.color_modes_visible = false
	
	color_picker.add_theme_constant_override("sv_width", 150)
	color_picker.add_theme_constant_override("sv_height", 150)
