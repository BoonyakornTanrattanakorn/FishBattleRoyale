extends CharacterBody2D

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var movement_speed: float = 200

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()

	velocity = input_dir * movement_speed

	move_and_slide()
