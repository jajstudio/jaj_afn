extends Control

@onready var name_text_edit = $CenterContainer/VBoxContainer/WorldName/Name
@onready var seed_text_edit = $CenterContainer/VBoxContainer/WorldSeed/Seed
@onready var difficulty_group = $CenterContainer/VBoxContainer/WorldDifficulty

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(OS.get_user_data_dir())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_pressed() -> void:
	Global.game_controller.change_gui_scene("res://scenes/menus/select_world.tscn")

func _on_create_pressed() -> void:
	# 1. Gather the data from the UI nodes
	var world_name = name_text_edit.text
	var world_seed = seed_text_edit.text

	# 2. Get the selected difficulty from the button group
	var difficulty = "Easy" # Default in case nothing is selected
	for button in difficulty_group.get_children():
		if button is Button and button.is_pressed():
			difficulty = button.text
			break

	# Check if a name was entered and if the seed is a valid number
	if world_name.is_empty():
		print("Please enter a world name.")
		return # Stop the function if no name is entered

	if not world_seed.is_valid_int():
		print("Please enter a valid integer for the seed.")
		return # Stop the function if seed is not an integer

	# 3. Create a dictionary to hold the data
	var world_data = {
	"name": world_name,
	"seed": int(world_seed), # Convert the seed to an integer
	"difficulty": difficulty,
	"changed_tiles_by_chunk": {}
	}

	# 4. Save the data to a JSON file
	var dir_path = "user://worlds/"
	if not DirAccess.dir_exists_absolute(dir_path):
		# This uses the static method `make_dir_absolute`
		var dir_creation_result = DirAccess.make_dir_absolute(dir_path)
		if dir_creation_result != OK:
			print("Error creating directory: " + dir_path)
			return

	# Check for a unique filename to prevent overwriting
	var file_name = world_name.strip_edges().replace(" ", "_").to_lower()
	var file_path = dir_path + file_name + ".json"

	if FileAccess.file_exists(file_path):
		print("A world with this name already exists!")
		return # Stop if the name is taken

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(world_data, "  "))
	file.close()

	print("World data saved successfully to " + file_path)

	# 5. Continue to the next scene
	Global.game_controller.change_gui_scene("res://scenes/menus/select_world.tscn")
	#Global.game_running = true
	#Global.is_multiplayer = false
