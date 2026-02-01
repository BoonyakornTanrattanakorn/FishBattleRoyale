extends CharacterBody2D

@export var speed := 800.0

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision:
		queue_free()  # Remove bullet on collision
