extends Control

const WORLDS_DIR_PATH = "user://worlds/"

# Get a reference to the container that will hold the world buttons.
@onready var world_list_container = $CenterContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var vbox = $CenterContainer/VBoxContainer

@onready var screen_width = get_viewport().size.x
@onready var screen_height = get_viewport().size.y

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Check if the world list container node was found.
	if world_list_container == null:
		print("Error: Node not found at path 'ScrollContainer/VBoxContainer'")
		return
	# Load the world buttons when the scene is ready.
	
	vbox.custom_minimum_size = Vector2(screen_width / 3, screen_height / 2)
	_load_world_buttons()

# This function reads the worlds directory and creates a button for each world file.
func _load_world_buttons() -> void:
	# Clear any existing buttons to prevent duplicates.
	for child in world_list_container.get_children():
		child.queue_free()

	# Create a DirAccess object to interact with the file system.
	var dir = DirAccess.open(WORLDS_DIR_PATH)
	
	# Check if the directory exists. If not, print a message and exit.
	if dir == null:
		print("Worlds directory not found: " + WORLDS_DIR_PATH)
		return
	
	# Start at the first file in the directory.
	dir.list_dir_begin()

	# Loop through all files in the directory.
	var file_name = dir.get_next()
	# Loop through all files in the directory.

	while file_name != "":
		# We're looking for files that end with the ".json" extension.
		if file_name.ends_with(".json"):
			# 1. Create a new Panel node to be the container.
			var panel = Panel.new()
			# Make the panel expand to fill the grid cell it's placed in.
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			# Apply the minimum size to the panel, not the button.
			panel.custom_minimum_size = Vector2(screen_width / 3, screen_height / 6)

			# 2. Create the Button node.
			var world_button = Button.new()
			
			# Make the button fill the entire panel.
			#world_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			
			# Get the world name from the file name (e.g., "my_world.json" becomes "My World").
			var world_name = file_name.replace(".json", "").replace("_", " ").capitalize()
			
			# Set the button's text to the world name.
			world_button.text = world_name
			
			# Connect the button's 'pressed' signal to a new function.
			var file_path = WORLDS_DIR_PATH + file_name
			world_button.pressed.connect(_on_world_button_pressed.bind(file_path))
			
			# 3. Add the button as a child of the panel.
			panel.add_child(world_button)
			
			# 4. Add the panel (with the button inside it) to your GridContainer.
			world_list_container.add_child(panel)
		
		# Move to the next file in the directory.
		file_name = dir.get_next()

	# Stop the directory listing.
	dir.list_dir_end()

# This function is called every frame.
func _process(_delta: float) -> void:
	# The _delta parameter is unused, so we prefix it with an underscore.
	pass

# This function is called when a world button is pressed.
func _on_world_button_pressed(file_path: String) -> void:
	# Load the world data from the file.
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Error opening file: " + file_path)
		return
	
	var world_data_json = file.get_as_text()
	file.close()
	
	# Parse the JSON data back into a dictionary.
	var world_data = JSON.parse_string(world_data_json)
	
	if world_data != null:
		print("Loaded world: " + world_data.name)
		# Check if the changed_tiles_by_chunk key exists.
		if world_data.has("changed_tiles_by_chunk"):
			var saved_data: Dictionary = world_data.changed_tiles_by_chunk
			var loaded_changed_tiles_by_chunk: Dictionary = {}

			# Iterate through the outer dictionary (chunks).
			for chunk_key in saved_data.keys():
				# We need to handle both the old Vector2i keys and the new string keys.
				var chunk_coords: Vector2i
				if typeof(chunk_key) == TYPE_STRING:
					# Convert the string key back to a Vector2i.
					var parts = chunk_key.strip_edges().trim_prefix("(").trim_suffix(")").split(",")
					chunk_coords = Vector2i(int(parts[0]), int(parts[1]))
				else:
					# Assume it's an old Vector2i key if not a string.
					chunk_coords = chunk_key

				loaded_changed_tiles_by_chunk[chunk_coords] = {}

				# Iterate through the inner dictionary (tiles).
				for tile_key in saved_data[chunk_key].keys():
					# We need to handle both the old Vector2i keys and the new string keys.
					var tile_coords: Vector2i
					if typeof(tile_key) == TYPE_STRING:
						# Convert the string key back to a Vector2i.
						var tile_parts = tile_key.strip_edges().trim_prefix("(").trim_suffix(")").split(",")
						tile_coords = Vector2i(int(tile_parts[0]), int(tile_parts[1]))
					else:
						# Assume it's an old Vector2i key if not a string.
						tile_coords = tile_key
					
					# Assign the tile data to the new dictionary.
					loaded_changed_tiles_by_chunk[chunk_coords][tile_coords] = saved_data[chunk_key][tile_key]

			# Replace the old dictionary with the new one.
			world_data["changed_tiles_by_chunk"] = loaded_changed_tiles_by_chunk

		# Use data to start the game
		Global.world_data = world_data
		Global.game_controller.change_game_scene(Global.preloaded_game_scene)
		Global.game_controller.change_gui_scene("res://scenes/menus/game_paused.tscn")
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		Global.game_running = true
	else:
		print("Error parsing JSON for file: " + file_path)
		print("This may be due to a corrupted or old save file. Please try creating and saving a new world.")

func _on_back_button_pressed() -> void:
	Global.game_controller.change_gui_scene("res://scenes/menus/main_menu.tscn")

func _on_new_button_pressed() -> void:
	Global.game_controller.change_gui_scene("res://scenes/menus/create_world.tscn")
