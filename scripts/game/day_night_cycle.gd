extends Node2D

## --- EXPORT VARIABLES (Editable in the Inspector) ---

# The duration of a full day-night cycle in real-world seconds.
@export var cycle_duration_seconds: float = 60.0

# The current time of day, from 0.0 (midnight) to 1.0 (next midnight).
# You can change this to start the game at a specific time.
# 0.25 is sunrise, 0.5 is noon, 0.75 is sunset.
@export_range(0.0, 1.0) var time_of_day: float = 0.25

# The gradient that defines the ambient color throughout the day.
# The left side of the gradient is midnight, and the middle is noon.
@export var ambient_color_gradient: Gradient


## --- NODE REFERENCES ---

# We need a reference to the CanvasModulate node to change its color.
# The script will find it automatically if it's a child node.
@onready var canvas_modulate: CanvasModulate = $CanvasModulate


## --- GAME LOOP ---

# The _process function is called on every frame.
func _process(delta: float) -> void:
	# 1. Update the time of day
	# We advance the time based on the cycle duration.
	# The fmod() function ensures that the time_of_day loops from 1.0 back to 0.0.
	time_of_day = fmod(time_of_day + (delta / cycle_duration_seconds), 1.0)

	# 2. Update the scene's tint
	update_ambient_color()


## --- HELPER FUNCTION ---

# This function gets the correct color from the gradient and applies it.
func update_ambient_color() -> void:
	# First, check if both the node and the gradient are set up to avoid errors.
	if not canvas_modulate or not ambient_color_gradient:
		print("Day/Night Cycle: CanvasModulate node or Gradient is not assigned!")
		return

	# Sample the gradient at the current time_of_day to get the desired color.
	var current_ambient_color = ambient_color_gradient.sample(time_of_day)

	# Apply the color to the CanvasModulate node, tinting the whole screen.
	canvas_modulate.color = current_ambient_color
