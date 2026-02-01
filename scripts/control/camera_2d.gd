# In a new script attached to the Camera2D node
extends Camera2D

func _process(_delta):
	# This forces the camera's final position to be on a whole pixel,
	# making the entire screen view pixel-perfect.
	global_position = global_position.round()
