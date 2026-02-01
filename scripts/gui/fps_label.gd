extends Label

func _process(_delta):
	# Engine.get_frames_per_second() returns the current FPS
	var fps = Engine.get_frames_per_second()

	# Update the Label's text
	self.text = "FPS: " + str(fps)
