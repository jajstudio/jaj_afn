extends Node2D

var velocity := Vector2.ZERO
var sway_time := 0.0
var sway_speed := randf_range(1.5, 3.0)
var sway_strength := randf_range(20.0, 50.0)
var landed := false

func _ready():
	velocity.y = randf_range(30.0, 60.0)
	$AnimatedSprite2D.play("fall")

func _process(delta):
	if landed:
		return
	
	sway_time += delta
	velocity.x = sin(sway_time * sway_speed) * sway_strength
	position += velocity * delta
	rotation = velocity.x * 0.01
	
	if position.y > randf_range(25, 70):
		landed = true
		velocity = Vector2.ZERO
		$AnimatedSprite2D.pause()
		_start_fade()

func _start_fade():
	await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, randf_range(0.5, 1.5))
	await tween.finished
	queue_free()
