extends CharacterBody2D
class_name BaseMob  # This allows other scripts to 'extend' it

@export_group("Movement Settings")
@export var speed: float = 30.0
@export var wander_range: float = 100.0

@export_group("Visuals")
@export var bob_speed: float = 0.0     # Set to 0 for mobs that don't fly
@export var bob_amplitude: float = 0.0 

var time_passed: float = 0.0
var target_position: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO
var is_loading: bool = false

# Default stats
var current_health: int = 100
var max_health: int = 100
var type: String = "BaseMob"

# Use @onready for nodes to ensure they exist before we call them
@onready var sprite = $AnimatedSprite2D
@onready var timer = $WanderTimer

func _ready():
	home_position = global_position
	_update_target_position()
	
	# Start the timer if it exists
	if timer:
		timer.start(randf_range(2.0, 5.0))
		timer.timeout.connect(_on_wander_timer_timeout)
	
	if not is_loading:
		_setup_mob()

func _physics_process(delta):
	_handle_movement(delta)
	_handle_visuals(delta)
	move_and_slide()

func _handle_movement(delta):
	var direction = global_position.direction_to(target_position)
	velocity = direction * speed
	
	if velocity.x != 0 and sprite:
		sprite.flip_h = velocity.x < 0
		
	if global_position.distance_to(target_position) < 10:
		_update_target_position()

func _handle_visuals(delta):
	if bob_speed > 0 and sprite:
		time_passed += delta
		sprite.position.y = sin(time_passed * bob_speed) * bob_amplitude

func _update_target_position():
	var random_offset = Vector2(
		randf_range(-wander_range, wander_range),
		randf_range(-wander_range, wander_range)
	)
	target_position = home_position + random_offset

# --- Boilerplate Functions ---

func _setup_mob():
	# Override this in child classes (e.g., play specific animations)
	pass

func _on_wander_timer_timeout():
	_update_target_position()
	if timer:
		timer.wait_time = randf_range(2.0, 5.0)

# --- Save/Load Logic ---

func get_save_data():
	return {
		"type": type,
		"current_health": current_health,
		"max_health": max_health,
		"pos": global_position,
		"over_world_mob": true
	}

func initialize_from_save(saved_pos: Vector2, saved_health: int):
	is_loading = true
	global_position = saved_pos
	home_position = saved_pos
	current_health = saved_health
	_update_target_position()
