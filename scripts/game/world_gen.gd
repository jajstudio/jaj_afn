extends Node2D

@onready var tilemap: TileMap = $WorldTileMap
@onready var tilefollower: Sprite2D = $TileFollower

@export var player: Node2D # Reference to player
@export var chunk_size := 6 # Must be 6 idk why
@export var view_distance := 10

var noise := FastNoiseLite.new()
var grass_noise := FastNoiseLite.new()
var generated_chunks := {}
var layer_index := 2 # The tilemap layer index to work on

# Store manually changed tiles by their chunk
var changed_tiles_by_chunk := {}

enum Layers { GROUND = 0, WATER = 1, FLOOR = 2, COLLISION = 3 }

enum Terrain { GRASS = 0, SAND = 1, WATER = 2, DIRT = 3 }

enum Foliage { }

# This dictionary holds all the rules/probabilities for placing decorations.
const DECORATION_RULES = {
	Terrain.GRASS: [
		{"tile": null, "weight": 94},
		{"tile": Vector2i(4, 4), "weight": 3},   # Tree

	],
	Terrain.SAND: [
	],
	Terrain.DIRT: [
		{"tile": null, "weight": 100},
	] 
}

func _ready() -> void:
	randomize()
	changed_tiles_by_chunk = Global.world_data.changed_tiles_by_chunk
	noise.seed = Global.world_data.seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_octaves = 6
	noise.frequency = 1.0 / 200.0
	
	grass_noise.seed = Global.world_data.seed + 1 # Use a different seed!
	grass_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	grass_noise.frequency = 1.0 / 35.0 # Smaller, more frequent features
	
	$SaveTimer.timeout.connect(_on_save_timer_timeout)
	#player = get_node("../Player")
	set_process(true)

func _process(_delta: float) -> void:
	var center := get_player_tile_coords()
	var center_chunk := get_chunk_coords(center)
	load_chunks_around(center_chunk)
	unload_far_chunks(center_chunk)

func _input(event):
	if event.is_action_pressed("change_tile"):
		var hovered_tile = tilefollower.get_hovered_tile_coords()
		change_tile_at_follower(hovered_tile, Terrain.GRASS)
		
func _on_save_timer_timeout() -> void:
	# Define paths for the main save file and a temporary one
	var world_name_lower = Global.world_data.name.strip_edges().replace(" ", "_").to_lower()
	var file_path = "user://worlds/" + world_name_lower + ".json"
	var temp_file_path = "user://worlds/" + world_name_lower + ".json.tmp"

	# --- Read existing data ---
	if not FileAccess.file_exists(file_path):
		print("Save file doesn't exist yet. Skipping read.")
		return # Or create a new default world_data dict here

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open world file for reading: %s" % file_path)
		return

	var file_content = file.get_as_text()
	file.close()

	var world_data = JSON.parse_string(file_content)
	if world_data == null:
		print("Error: Could not parse world data from file.")
		return
	
	# --- Prepare new data ---
	var serializable_changed_tiles := {}
	for chunk_coords in changed_tiles_by_chunk.keys():
		var chunk_key = str(chunk_coords)
		serializable_changed_tiles[chunk_key] = {}
		for tile_coords in changed_tiles_by_chunk[chunk_coords].keys():
			var tile_key = str(tile_coords)
			serializable_changed_tiles[chunk_key][tile_key] = changed_tiles_by_chunk[chunk_coords][tile_coords]
			
	world_data["changed_tiles_by_chunk"] = serializable_changed_tiles.duplicate(true)

	# --- Write new data to the temp file ---
	var temp_file = FileAccess.open(temp_file_path, FileAccess.WRITE)
	if temp_file == null:
		print("Error: Could not open temporary save file for writing: %s" % temp_file_path)
		return
		
	temp_file.store_string(JSON.stringify(world_data, "\t"))
	temp_file.close()
	
	# --- Use temp file to replace the old save with the new one ---
	var err = DirAccess.rename_absolute(temp_file_path, file_path)
	if err != OK:
		print("Error: Failed to rename temp file, save failed!")
	
func change_tile_at_follower(tile_coords: Vector2i, terrain_type: int):
	var chunk_coords = get_chunk_coords(tile_coords)	
	if not changed_tiles_by_chunk.has(chunk_coords):
		changed_tiles_by_chunk[chunk_coords] = {}
	
	# Create a dictionary to hold both the terrain type and layer index
	var tile_data = {
		"terrain_type": terrain_type,
		"layer_index": layer_index  # Save the current layer index
	}
	
	changed_tiles_by_chunk[chunk_coords][tile_coords] = tile_data
	
	if generated_chunks.has(chunk_coords):
		generated_chunks.erase(chunk_coords)
	
func get_player_tile_coords() -> Vector2i:
	return tilemap.local_to_map(player.global_position)

func get_chunk_coords(tile_coords: Vector2i) -> Vector2i:
	return Vector2i(
		floor(float(tile_coords.x) / chunk_size),
		floor(float(tile_coords.y) / chunk_size)
	)
	
func load_chunks_around(center_chunk: Vector2i):
	# Iterate in a spiral pattern from the center outwards
	for r in range(view_distance + 1):
		for i in range(-r, r + 1):
			# Top and bottom edges of the spiral ring
			var top_chunk = center_chunk + Vector2i(i, -r)
			if not generated_chunks.has(top_chunk):
				generate_chunk(top_chunk)
				generated_chunks[top_chunk] = true
				return # <- Exit after generating one chunk

			var bottom_chunk = center_chunk + Vector2i(i, r)
			if not generated_chunks.has(bottom_chunk):
				generate_chunk(bottom_chunk)
				generated_chunks[bottom_chunk] = true
				return # <- Exit after generating one chunk

			# Left and right edges of the spiral ring
			var left_chunk = center_chunk + Vector2i(-r, i)
			if not generated_chunks.has(left_chunk):
				generate_chunk(left_chunk)
				generated_chunks[left_chunk] = true
				return # <- Exit after generating one chunk
				
			var right_chunk = center_chunk + Vector2i(r, i)
			if not generated_chunks.has(right_chunk):
				generate_chunk(right_chunk)
				generated_chunks[right_chunk] = true
				return # <- Exit after generating one chunk

func unload_far_chunks(center_chunk: Vector2i):
	var keys_to_remove := []
	for chunk in generated_chunks.keys():
		if abs(chunk.x - center_chunk.x) > view_distance + 1 or abs(chunk.y - center_chunk.y) > view_distance + 1:
			clear_chunk(chunk)
			keys_to_remove.append(chunk)
	for chunk in keys_to_remove:
		generated_chunks.erase(chunk)

func clear_chunk(chunk_coords: Vector2i):
	var start_x = chunk_coords.x * chunk_size
	var start_y = chunk_coords.y * chunk_size
	var area = Rect2i(start_x, start_y, chunk_size, chunk_size)
	
	for x in range(area.position.x, area.position.x + area.size.x):
		for y in range(area.position.y, area.position.y + area.size.y):
			for layer in Layers.keys():
				tilemap.set_cell(Layers[layer], Vector2i(x, y), -1)

func generate_chunk(chunk_coords: Vector2i):
	# Initial setup (same as before)
	var start_x = chunk_coords.x * chunk_size
	var start_y = chunk_coords.y * chunk_size
	var rng = RandomNumberGenerator.new()
	var value_to_hash = [Global.world_data.seed, chunk_coords]
	rng.seed = hash(value_to_hash)

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			var tile_pos = Vector2i(x, y)
			
			# --- Step 1: Place Base Terrain ---
			# We still need the base terrain for the ground layer and decoration rules.
			var base_terrain: int = get_terrain_from_noise(tile_pos)
			if base_terrain == Terrain.WATER:
				BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.SAND)
				BetterTerrain.set_cell(tilemap, Layers.FLOOR, tile_pos, base_terrain)
			else:
				BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, base_terrain)
			
			# --- Step 2: Place Grass Using Combined Noise ---
			# Get the raw noise values for both generators.
			var terrain_val = noise.get_noise_2d(tile_pos.x, tile_pos.y)
			var grass_val = grass_noise.get_noise_2d(tile_pos.x, tile_pos.y)
			
			# Combine them to create a "fertility" score.
			var fertility = terrain_val + grass_val

			# Set a single threshold for grass to grow.
			# Adjust this value to control how much grass appears and how far it spreads.
			# A lower value (e.g., 0.3) means more grass.
			# A higher value (e.g., 0.6) means less grass.
			var fertility_threshold = 0.25
			if fertility > fertility_threshold:
				BetterTerrain.set_cell(tilemap, Layers.FLOOR, tile_pos, Terrain.GRASS)
				base_terrain = Terrain.GRASS

			# --- Step 3: Place Decorations ---
			if DECORATION_RULES.has(base_terrain):
				# ... (rest of the decoration code is the same)
				var possible_decorations = DECORATION_RULES[base_terrain]
				var total_weight = 0
				for decoration in possible_decorations:
					total_weight += decoration.weight
				var random_pick = rng.randi_range(1, total_weight)
				var chosen_tile = null
				for decoration in possible_decorations:
					random_pick -= decoration.weight
					if random_pick <= 0:
						chosen_tile = decoration.tile
						break
				if chosen_tile != null:
					tilemap.set_cell(Layers.COLLISION, tile_pos, 0, chosen_tile)

	# --- Apply manual changes and update autotiling (same as before) ---
	var changed_tiles_in_this_chunk: Dictionary = changed_tiles_by_chunk.get(chunk_coords, {})
	# ... (rest of the function is the same)
	for tile_pos in changed_tiles_in_this_chunk.keys():
		var tile_data = changed_tiles_in_this_chunk[tile_pos]
		var terrain_type = tile_data.get("terrain_type", Terrain.GRASS)
		var saved_layer_index = tile_data.get("layer_index", layer_index)
		BetterTerrain.set_cell(tilemap, saved_layer_index, tile_pos, terrain_type)

	var update_area = Rect2i(start_x - 1, start_y - 1, chunk_size + 2, chunk_size + 2)
	for layer in Layers.keys():
		BetterTerrain.update_terrain_area(tilemap, Layers[layer], update_area)

# Helper function to determine terrain type for world gen.
func get_terrain_from_noise(tile_coords: Vector2i) -> int:
	var val = noise.get_noise_2d(tile_coords.x, tile_coords.y)
	if val < -0.2:
		return Terrain.WATER
	elif val < 0.0:
		return Terrain.SAND
	else:
		return Terrain.DIRT
