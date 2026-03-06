extends BaseMob

func _setup_mob():
	type = "Bee"
	bob_speed = 5.0     # Set to 0 for mobs that don't fly
	bob_amplitude = 5.0 
	current_health = 10
	max_health = 10
	sprite.play("fly")
	# All the movement and bobbing logic is handled by the parent!
