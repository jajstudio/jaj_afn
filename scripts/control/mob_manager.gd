extends Node2D

@export var bee_scene: PackedScene
@export var max_total_mobs: int = 30
@export var mob_limits = {"Bee": 8} # Limits specific mobs
@onready var world_tile_map = get_node("../WorldTileMap") 
@export var chunk_size: int = 6 # Set this to match your generation script
@export var region_size_in_chunks: int = 20

var active_mobs = []
var region_mob_counts = {} 
var remembered_mobs = {} 

func _process(_delta):
	# Only run every ~30 frames to save CPU
	if Engine.get_frames_drawn() % 30 == 0:
		clean_up_mobs()
		if active_mobs.size() < max_total_mobs:
			try_spawn_bee()

func try_spawn_bee():
	var player = get_node("../Player")
	var region_pos = get_region_pos(player.global_position)
	
	# 1. Count active mobs in this region
	var current_region_count = 0
	for mob in active_mobs:
		if get_region_pos(mob.global_position) == region_pos:
			current_region_count += 1
			
	# 2. Count REMEMBERED mobs in this region
	# (Optional: prevents spawning if the player previously 'filled' the region)
	for c_pos in remembered_mobs.keys():
		if get_region_from_chunk(c_pos) == region_pos:
			current_region_count += remembered_mobs[c_pos].size()

	# 3. Only spawn if under the REGION limit
	if current_region_count < mob_limits["Bee"]:
		spawn_at_random_edge()

func spawn_at_random_edge():
	var player = get_node("../Player") # Path to your Player node
	var angle = randf() * TAU
	var spawn_dist = 800 # Slightly larger than screen width
	var spawn_pos = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_dist
	
	var new_bee = bee_scene.instantiate()
	new_bee.global_position = spawn_pos
	new_bee.add_to_group("Bee")
	add_child(new_bee)
	active_mobs.append(new_bee)

func clean_up_mobs():
	var player = get_node("../Player")
	for i in range(active_mobs.size() -1, -1, -1):
		var mob = active_mobs[i]
		if is_instance_valid(mob) and mob.global_position.distance_to(player.global_position) > 1100:
			save_mob_to_memory(mob) # <--- Save data before deleting
			active_mobs.remove_at(i)
			mob.queue_free()
			
func save_mob_to_memory(mob):
	var chunk_pos = world_tile_map.local_to_map(mob.global_position) / chunk_size
	if not remembered_mobs.has(chunk_pos):
		remembered_mobs[chunk_pos] = []
		remembered_mobs[chunk_pos].append(mob.get_save_data())
		
func get_region_pos(global_pos: Vector2) -> Vector2i:
	var map_pos = world_tile_map.local_to_map(global_pos)
	# Divide tile position by (chunk_size * region_size)
	var r_size = chunk_size * region_size_in_chunks
	return Vector2i(
		floor(float(map_pos.x) / r_size),
		floor(float(map_pos.y) / r_size)
	)
		
func load_mobs_for_chunk(chunk_pos: Vector2i):
	# Check if we have any data saved for this specific chunk
	if remembered_mobs.has(chunk_pos):
		var mobs_to_spawn = remembered_mobs[chunk_pos]
		
		for data in mobs_to_spawn:
			var new_mob
			if data["type"] == "Bee":
				new_mob = bee_scene.instantiate()
			
			if new_mob:
				add_child(new_mob)
				if new_mob.has_method("initialize_from_save"):
					new_mob.initialize_from_save(data["pos"], data["health"])
				new_mob.add_to_group("Bee")
				active_mobs.append(new_mob)
		
		# IMPORTANT: Clear the memory for this chunk so we don't 
		# double-spawn them if the function is called again
		remembered_mobs.erase(chunk_pos)
		
func get_region_from_chunk(chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		floor(float(chunk_pos.x) / region_size_in_chunks),
		floor(float(chunk_pos.y) / region_size_in_chunks)
	)
