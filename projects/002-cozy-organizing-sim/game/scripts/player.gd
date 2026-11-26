extends CharacterBody2D
## Top-down placeholder player with acceleration/friction, kept inside the visible screen.

@export var max_speed := 420.0
@export var acceleration := 3000.0
@export var friction := 2600.0
@export var half_size := Vector2(24, 24)


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	var screen := get_viewport_rect()
	position = position.clamp(screen.position + half_size, screen.end - half_size)
