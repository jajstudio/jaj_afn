extends CharacterBody2D

@export var speed: float = 60.0
@export var wander_range: float = 100.0

var target_position: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO
var health: int = 10
var type: String = "Bee"

func _ready():
	home_position = global_position
	_update_target_position()
	$WanderTimer.start(randf_range(2.0, 5.0)) # Randomize start time

func _physics_process(delta):
	# Move towards target
	var direction = global_position.direction_to(target_position)
	velocity = direction * speed
	
	# Simple flip logic based on movement
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0
		
	move_and_slide()

	# If we are close to the target, pick a new one
	if global_position.distance_to(target_position) < 10:
		_update_target_position()

func _update_target_position():
	# Pick a random spot around the home/spawn point
	var random_offset = Vector2(
		randf_range(-wander_range, wander_range),
		randf_range(-wander_range, wander_range)
	)
	target_position = home_position + random_offset
	
func initialize_from_save(saved_pos: Vector2, saved_health: int):
	global_position = saved_pos
	home_position = saved_pos # Update home to the actual forest location
	health = saved_health
	_update_target_position() # Recalculate target near the new home

func get_save_data():
	return {
		"type": type,
		"health": health,
		"pos": global_position,
		"over_world_mob": true
	}

func _on_wander_timer_timeout():
	_update_target_position()
	$WanderTimer.wait_time = randf_range(2.0, 5.0)
