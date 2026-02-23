extends Node2D

@onready var tilemap: TileMap = $WorldTileMap
@onready var tilefollower: Sprite2D = $TileFollower
@onready var object_container = $Objects # Node to hold objects (i.e. trees, plants, pots etc.)
@onready var minimap =  get_tree().get_first_node_in_group("minimap")

@export var player: Node2D 
@export var chunk_size := 6 # Must be 6 idk why so leave it
@export var view_distance := 8 # How many chunks to render around the player
@export var tree: PackedScene = preload("res://scenes/game/worldgen/tree.tscn")
@export var plant: PackedScene = preload("res://scenes/game/worldgen/plant.tscn")
@export var placeable: PackedScene = preload("res://scenes/game/worldgen/staticobject.tscn")

var temperature := FastNoiseLite.new()
var moisture := FastNoiseLite.new()
var altitude := FastNoiseLite.new()
var varieties = null
var random_type = null
var object_spawn_rng = RandomNumberGenerator.new()

var generated_chunks := {} # Stores already generated chunks
var chunk_containers = {} # Used to tie objects to their respective chunk

# The tilemap layer for the player to edit tiles at
var layer_index := 3

# Used to store tiles changed by the player by their chunk
var changed_tiles_by_chunk := {}

# Tilemap layers
enum Layers { UNDERWATER = 0, WATERSHADER = 1, WATER = 2, GROUND = 3, FLOOR = 4, FLOOR_DECOR = 5,  COLLISION = 6 }

# Tiles/Terrains used in chunk generation
enum Terrain { 
	GRASS = 0, 
	SAND = 1, 
	WATER = 2, 
	DIRT = 3, 
	SNOW = 4, 
	HAUNT = 5, 
	PLAIN = 6, 
	STONE = 7, 
	AUTUMM = 8,
	MATTED_GRASS = 9,
	WATER_EDGE = 10
	}

# Decoration tiles that cannot be interacted with, used as an overlay
var DECORATIONS = {
	"forest_flower_white_1": Vector2i(17, 0),
	"forest_flower_white_2": Vector2i(18, 0),
	"forest_flower_white_3": Vector2i(19, 0),
	"forest_flower_white_4": Vector2i(20, 0),
	"forest_flower_white_5": Vector2i(21, 0),
	"forest_ground_grass_1": Vector2i(17, 1),
	"forest_ground_grass_2": Vector2i(18, 1),
	"forest_ground_grass_3": Vector2i(19, 1),
	"forest_ground_grass_4": Vector2i(20, 1),
	"forest_ground_grass_5": Vector2i(21, 1),
}

func _ready() -> void:
	randomize()
	# Load in tiles changed by the player
	changed_tiles_by_chunk = Global.world_data.changed_tiles_by_chunk
	
	# World gen settings
	object_spawn_rng.seed = Global.world_data.seed
	
	temperature.seed = Global.world_data.seed # Load in the saved world seed
	temperature.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature.fractal_octaves = 5
	temperature.frequency = 1.0 / 5000
	
	moisture.seed = Global.world_data.seed + 1
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture.fractal_octaves = 5
	moisture.frequency = 1.0 / 4500
	
	altitude.seed = Global.world_data.seed + 2
	altitude.noise_type = FastNoiseLite.TYPE_SIMPLEX
	altitude.fractal_octaves = 5
	altitude.frequency = 1.0 / 1200
	
	$SaveTimer.timeout.connect(_on_save_timer_timeout) # Start timer to save world data
	set_process(true)

func _process(_delta: float) -> void:
	var center := get_player_tile_coords()
	var center_chunk := get_chunk_coords(center)
	load_chunks_around(center_chunk)
	unload_far_chunks(center_chunk)
	#minimap.update_player_position(get_player_tile_coords())

func _input(event):
	if event.is_action_pressed("change_tile"):
		var hovered_tile = tilefollower.get_hovered_tile_coords()
		change_tile_at_follower(hovered_tile, Terrain.SAND)
		
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
	#minimap.open_full_map()
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
				#generate_chunk(top_chunk)
				generate_chunk_new(top_chunk)
				generated_chunks[top_chunk] = true
				return # <- Exit after generating one chunk

			var bottom_chunk = center_chunk + Vector2i(i, r)
			if not generated_chunks.has(bottom_chunk):
				#generate_chunk(bottom_chunk)
				generate_chunk_new(bottom_chunk)
				generated_chunks[bottom_chunk] = true
				return # <- Exit after generating one chunk

			# Left and right edges of the spiral ring
			var left_chunk = center_chunk + Vector2i(-r, i)
			if not generated_chunks.has(left_chunk):
				#generate_chunk(left_chunk)
				generate_chunk_new(left_chunk)
				generated_chunks[left_chunk] = true
				return # <- Exit after generating one chunk
				
			var right_chunk = center_chunk + Vector2i(r, i)
			if not generated_chunks.has(right_chunk):
				#generate_chunk(right_chunk)
				generate_chunk_new(right_chunk)
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
	if chunk_containers.has(chunk_coords):
		var container = chunk_containers[chunk_coords]
		container.queue_free() # Deletes the container and all objects inside it
		chunk_containers.erase(chunk_coords) # Remove from dictionary

func get_or_create_chunk_container(chunk_coords: Vector2i):
	# If container already exists get it and skip the rest
	if chunk_containers.has(chunk_coords):
		return chunk_containers[chunk_coords]
	
	# Create a new object container for this chunk if it didn't already exist
	var container = Node2D.new()
	container.name = "Chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	container.y_sort_enabled = true 
	
	object_container.add_child(container)
	chunk_containers[chunk_coords] = container
	return container

func generate_chunk_new(chunk_coords: Vector2i):
	var start_x = chunk_coords.x * chunk_size
	var start_y = chunk_coords.y * chunk_size
	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			# World gen setup
			var tile_pos = Vector2i(x, y)
			var temp = 2 * (abs(temperature.get_noise_2d(x, y)))
			var moist = 2 * (abs(moisture.get_noise_2d(x, y)))
			var alt = 2 * (abs(altitude.get_noise_2d(x, y)))
			var tile_seed = Global.world_data.seed + (tile_pos.x * 374761393) + (tile_pos.y * 668265263)
			# Seed the generator based off the current tile to ensure consistent object spawns
			object_spawn_rng.seed = tile_seed
			# Biome Generation
			# Ocean
			if alt < 0.2:
				BetterTerrain.set_cell(tilemap, Layers.UNDERWATER, tile_pos, Terrain.SAND)
				BetterTerrain.set_cell(tilemap, Layers.WATER, tile_pos, Terrain.WATER)
				BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.WATER_EDGE)
				#minimap.paint_tile(tile_pos, "water")
			# Beach
			elif between(alt, 0.2, 0.25):
				BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.SAND)
				#minimap.paint_tile(tile_pos, "sand")
			elif between(alt, 0.25, 0.8):
				var is_plains = between(moist, 0, 0.4) and between(temp, 0.2, 0.6)
				var is_autumn = between(moist, 0.4, 0.9) and (temp > 0.6)
				var is_desert = temp > 0.7 and moist < 0.4
				if is_plains:
					BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.PLAIN)
				elif is_autumn:
					BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.AUTUMM)
				elif is_desert:
					BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.STONE)
				else:
					generate_forest(tile_pos, chunk_coords)
			else:
				generate_forest(tile_pos, chunk_coords)
	# Update tiles changed by the player
	var changed_tiles_in_this_chunk: Dictionary = changed_tiles_by_chunk.get(chunk_coords, {})
	for tile_pos in changed_tiles_in_this_chunk.keys():
		var tile_data = changed_tiles_in_this_chunk[tile_pos]
		var terrain_type = tile_data.get("terrain_type", Terrain.GRASS)
		var saved_layer_index = tile_data.get("layer_index", layer_index)
		BetterTerrain.set_cell(tilemap, saved_layer_index, tile_pos, terrain_type)

	var update_area = Rect2i(start_x - 1, start_y - 1, chunk_size + 2, chunk_size + 2)
	for layer in Layers.keys():
		BetterTerrain.update_terrain_area(tilemap, Layers[layer], update_area)
			
func between(val, start, end):
	if start <= val and val < end:
		return true

func generate_forest(tile_pos, chunk_coords: Vector2i):
	var detail_noise = altitude.get_noise_2d(tile_pos.x * 15.0, tile_pos.y * 15.0) # used to generate micro biomes
	var secondary_detail_noise = altitude.get_noise_2d(tile_pos.x * 50.0, tile_pos.y * 50.0) # used to spawn floor decor
	var density = altitude.get_noise_2d(tile_pos.x * 2.0, tile_pos.y * 2.0) # used to control frequency of micro biomes
	if detail_noise < -0.6 and density < -0.3: # WATER
		BetterTerrain.set_cell(tilemap, Layers.UNDERWATER, tile_pos, Terrain.SAND)
		BetterTerrain.set_cell(tilemap, Layers.WATER, tile_pos, Terrain.WATER)
		BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.WATER_EDGE)
		#minimap.paint_tile(tile_pos, "water")
	elif between(detail_noise, -1, -.5) and density < -0.25: # SAND BORDERS AROUND WATER
		BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.SAND)
		if between(detail_noise, -0.7, -.57):
			if 0.2 < object_spawn_rng.randf() and object_spawn_rng.randf() < 0.9:
				var new_plant = spawn_object(tile_pos, chunk_coords, plant)
				varieties = ["forest_pond_reed_1","forest_pond_reed_2","forest_pond_reed_3"]
				random_type = varieties[object_spawn_rng.randi() % varieties.size()]
				new_plant.set_plant_type(random_type)
		elif between(detail_noise, -.52, -.5):
			varieties = ["forest_ground_grass_1", "forest_ground_grass_2", "forest_ground_grass_3", "forest_ground_grass_4","forest_ground_grass_5"]
			random_type = varieties[object_spawn_rng.randi() % varieties.size()]
			tilemap.set_cell(Layers.FLOOR_DECOR, tile_pos, 0, DECORATIONS[random_type])
			varieties = ["forest_plant_1", "forest_plant_2", "forest_plant_3", "forest_plant_4", "forest_plant_5"]
			if 0 < object_spawn_rng.randf() and object_spawn_rng.randf() < 0.3:
				var new_plant = spawn_object(tile_pos, chunk_coords, plant)
				random_type = varieties[object_spawn_rng.randi() % varieties.size()]
				new_plant.set_plant_type(random_type)
		elif between(detail_noise, -.54, -.52):
			varieties = ["forest_plant_1", "forest_plant_2", "forest_plant_3", "forest_plant_4", "forest_plant_5"]
			if 0 < object_spawn_rng.randf() and object_spawn_rng.randf() < 0.5:
				var new_plant = spawn_object(tile_pos, chunk_coords, plant)
				random_type = varieties[object_spawn_rng.randi() % varieties.size()]
				new_plant.set_plant_type(random_type)
		#minimap.paint_tile(tile_pos, "sand")
	elif between(detail_noise, .1, 0.3): # MATTED GRASS
		BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.MATTED_GRASS)
		#minimap.paint_tile(tile_pos, "grass")
		# Foliage
		if 0.6 < object_spawn_rng.randf() and object_spawn_rng.randf() < 0.9:
			var new_plant = spawn_object(tile_pos, chunk_coords, plant)
			varieties = ["forest_plant_1", "forest_plant_2", "forest_plant_3", "forest_plant_4", "forest_plant_5",]
			random_type = varieties[object_spawn_rng.randi() % varieties.size()]
			new_plant.set_plant_type(random_type)
		elif object_spawn_rng.randf() > 0.90:
			spawn_object(tile_pos, chunk_coords, tree)
	elif between(detail_noise, 0.6, 0.7): # STONE MICRO BIOME
		BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.STONE)
		#minimap.paint_tile(tile_pos, "stone")
		if object_spawn_rng.randf() > .95:
			spawn_object(tile_pos, chunk_coords, placeable)
	else: # FILL WITH FOREST
		# Grass/Tiles
		BetterTerrain.set_cell(tilemap, Layers.GROUND, tile_pos, Terrain.MATTED_GRASS)
		BetterTerrain.set_cell(tilemap, Layers.FLOOR, tile_pos, Terrain.GRASS)
		#minimap.paint_tile(tile_pos, "grass")
		# Floor Decor (flowers pebbles etc)
		if between(secondary_detail_noise, .4, 8):
			varieties = ["forest_flower_white_1", "forest_flower_white_2", "forest_flower_white_3", "forest_flower_white_4", "forest_flower_white_5"]
			random_type = varieties[object_spawn_rng.randi() % varieties.size()]
			tilemap.set_cell(Layers.FLOOR_DECOR, tile_pos, 0, DECORATIONS[random_type])
		# Foliage
		if 0.6 < object_spawn_rng.randf() and object_spawn_rng.randf() < 0.9:
			var new_plant = spawn_object(tile_pos, chunk_coords, plant)
			varieties = ["forest_plant_1", "forest_plant_2", "forest_plant_3", "forest_plant_4", "forest_plant_5"]
			random_type = varieties[object_spawn_rng.randi() % varieties.size()]
			new_plant.set_plant_type(random_type)
		elif object_spawn_rng.randf() > 0.90:
			spawn_object(tile_pos, chunk_coords, tree)

func spawn_object(tile_pos: Vector2i, chunk_coords: Vector2i, scene_to_spawn: PackedScene):
	var container = get_or_create_chunk_container(chunk_coords)
	var instance = scene_to_spawn.instantiate()
	
	instance.position = tilemap.map_to_local(tile_pos)
	instance.tile_pos = tile_pos
	container.add_child(instance)
	return instance
