extends CharacterBody2D


const WALK_SPEED = 300.0
const SPRINT_SPEED = 600.0

@onready var sprite_2d: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	var speed = WALK_SPEED
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		
	var direction_x := Input.get_axis("left", "right")
	if direction_x:
		velocity.x = direction_x * speed
		if direction_x < 0:
			sprite_2d.flip_h = true
		else:
			sprite_2d.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	var direction_y := Input.get_axis("up", "down")
	if direction_y:
		velocity.y = direction_y * speed
	else:
		velocity.y = move_toward(velocity.y, 0, speed)
	move_and_slide()
