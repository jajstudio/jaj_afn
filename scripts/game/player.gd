extends CharacterBody2D

@export var speed := 100

@onready var eye_sprite: Sprite2D = $PlayerBody/Eyes
@onready var head_sprite: Sprite2D = $PlayerBody/Head
@onready var torso_sprite: Sprite2D = $PlayerBody/Torso
@onready var hand_sprite: Sprite2D = $PlayerBody/Hands
@onready var hair_sprite: Sprite2D = $PlayerBody/Hair
@onready var shirt_sprite: Sprite2D = $PlayerBody/Shirt
@onready var leg_sprite: Sprite2D = $PlayerBody/Legs
@onready var feet_sprite: Sprite2D = $PlayerBody/Feet

@onready var eye_dart_timer: Timer = $EyeDartTimer
@onready var run_animation_timer = $RunAnimationTimer
@export var base_animation_interval = 0.1

# --- Animation Variables ---
enum RunDir { LEFT, RIGHT, UP, DOWN }
var current_run_dir: RunDir = RunDir.RIGHT

# An array to hold the keys for the run animation frames in order
const RUN_FRAMES_RIGHT = [
	"default_run1_right",
	"default_run1_right", 
	"default_run2_right",  
	"default_run3_right",
]

const RUN_FRAMES_LEFT = [
	"default_run1_left",
	"default_run1_left", 
	"default_run2_left",  
	"default_run3_left",
]

const RUN_FRAMES_DOWN = [
	"default_run1_down",
	"default_run2_down", 
	"default_run2_down",  
	"default_run3_down",
]

# This variable will track which frame we are on (e.g., 0, 1, 2, 3)
var current_run_frame = 0

const EYE_REGIONS = {
	"look_left": Rect2(22, 2, 6, 2),
	"look_right": Rect2(22, 8, 6, 2),
}

const BODY_REGIONS = {
	"default_down": Rect2(25, 8, 12, 4),
	"default_up": Rect2(22, 2, 6, 2),
	"default_left": Rect2(8, 8, 12, 4),
	"default_right": Rect2(42, 8, 12, 4),
}

const HAND_REGIONS = {
	"default_down": Rect2(25, 13, 12, 3),
	"default_up": Rect2(22, 2, 6, 2),
	"default_left": Rect2(8, 13, 12, 3),
	"default_right": Rect2(42, 13, 12, 3),
}

const LEG_REGIONS = {
	"default_down": Rect2(12, 20, 6, 3),
	"default_up": Rect2(22, 2, 6, 2),
	"default_left": Rect2(4, 20, 6, 3),
	"default_right": Rect2(20, 20, 6, 3),
	"default_down_running1": Rect2(12, 25, 6, 3),
	"default_down_running2": Rect2(12, 30, 6, 3),
}

const HEAD_REGIONS = {
	"default_down": Rect2(41, 7, 10, 9),
	"default_up": Rect2(22, 2, 6, 2),
	"default_left": Rect2(23, 7, 12, 9),
	"default_right": Rect2(57, 7, 12, 9),
}

const FEET_REGIONS = {
	"default_down": Rect2(12, 13, 8, 3),
	"default_up": Rect2(22, 2, 6, 2),
	"default_left": Rect2(2, 13, 8, 3),
	"default_right": Rect2(22, 13, 8, 3),
	"default_run1_left": Rect2(164, 11, 10, 7),
	"default_run2_left": Rect2(154, 11, 8, 7),
	"default_run3_left": Rect2(144, 11, 6, 7),
	"default_run1_right": Rect2(112, 11, 10, 7),
	"default_run2_right": Rect2(124, 11, 8, 7),
	"default_run3_right": Rect2(136, 11, 6, 7),
	"default_run1_down": Rect2(192, 12, 6, 3),
	"default_run2_down": Rect2(203, 12, 6, 3),
	"default_run3_down": Rect2(214, 12, 6, 3),
}

var eye_directions: Array

func _ready():
	eye_sprite.region_enabled = true
	eye_directions = EYE_REGIONS.keys()
	
	eye_dart_timer.timeout.connect(_on_eye_dart_timer_timeout)
	run_animation_timer.timeout.connect(_on_animation_timer_timeout)

	_on_eye_dart_timer_timeout()
	
func _process(_delta):
	var mouse_position = get_global_mouse_position()
	var to_mouse = mouse_position - self.global_position

	var diagonal_threshold = 0.75
	var direction_string = ""

	if to_mouse.y < -abs(to_mouse.x) * diagonal_threshold:
		direction_string += "Up"
	elif to_mouse.y > abs(to_mouse.x) * diagonal_threshold:
		direction_string += "Down"
	if to_mouse.x < -abs(to_mouse.y) * diagonal_threshold:
		direction_string += "Left"
	elif to_mouse.x > abs(to_mouse.y) * diagonal_threshold:
		direction_string += "Right"

	# This logic assumes you will add Up and Left run animations later.
	# For now, it animates only when moving right.
	if(direction_string) == "Down":
		shirt_sprite.region_rect = BODY_REGIONS["default_down"]
		hand_sprite.region_rect = HAND_REGIONS["default_down"]
		head_sprite.region_rect = HEAD_REGIONS["default_down"]
		leg_sprite.region_rect = LEG_REGIONS["default_down"]
		if velocity == Vector2.ZERO:	
			feet_sprite.region_rect = FEET_REGIONS["default_down"]
	
		current_run_dir = RunDir.DOWN
		
	elif(direction_string.contains("Right")):
		shirt_sprite.region_rect = BODY_REGIONS["default_right"]
		hand_sprite.region_rect = HAND_REGIONS["default_right"]
		leg_sprite.region_rect = LEG_REGIONS["default_right"]
		head_sprite.region_rect = HEAD_REGIONS["default_right"]
		if velocity == Vector2.ZERO:
			feet_sprite.region_rect = FEET_REGIONS["default_right"]
		current_run_dir = RunDir.RIGHT
		
	elif(direction_string.contains("Left")):
		shirt_sprite.region_rect = BODY_REGIONS["default_left"]
		hand_sprite.region_rect = HAND_REGIONS["default_left"]
		leg_sprite.region_rect = LEG_REGIONS["default_left"]
		head_sprite.region_rect = HEAD_REGIONS["default_left"]
		if velocity == Vector2.ZERO:
			feet_sprite.region_rect = FEET_REGIONS["default_left"]
		current_run_dir = RunDir.LEFT

	# --- Animation Timer Logic ---
	if velocity.length() > 0:
		var speed_ratio = velocity.length() / speed
		run_animation_timer.wait_time = base_animation_interval / speed_ratio
		
		if run_animation_timer.is_stopped():
			run_animation_timer.start()
	else:
		run_animation_timer.stop()
		current_run_frame = 0 # Reset animation for the next run
		
		
func _physics_process(_delta):
	Global.player_position = self.global_position
	
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

func get_run_frames() -> Array:
	match current_run_dir:
		RunDir.LEFT:
			return RUN_FRAMES_LEFT
		RunDir.RIGHT:
			return RUN_FRAMES_RIGHT
		RunDir.DOWN:
			return RUN_FRAMES_DOWN
		_:
			return RUN_FRAMES_RIGHT # fallback for now

func _on_animation_timer_timeout():
	var run_frames := get_run_frames()
	print(run_frames)

	current_run_frame = (current_run_frame + 1) % run_frames.size()
	var frame_key = run_frames[current_run_frame]

	feet_sprite.region_rect = FEET_REGIONS[frame_key]

func _on_eye_dart_timer_timeout():
	var random_direction = eye_directions.pick_random()
	change_eyes(random_direction)
	eye_dart_timer.wait_time = randf_range(1.0, 4.0)
	eye_dart_timer.start()

func change_eyes(expression: String):
	if EYE_REGIONS.has(expression):
		eye_sprite.region_rect = EYE_REGIONS[expression]
	else:
		print("Error: Eye expression not found: ", expression)
		
func change_skin_color(new_color: Color):
	head_sprite.modulate = new_color
	torso_sprite.modulate = new_color
	hand_sprite.modulate = new_color

func change_hair_color(new_color: Color):
	hair_sprite.modulate = new_color
	
func change_eye_color(new_color: Color):
	eye_sprite.modulate = new_color
