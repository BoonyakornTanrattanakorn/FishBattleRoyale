extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#pass # Replace with function body.
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Powerup collected by: ", body.name)
		
		print("Speed before: ", body.movement_speed)
		body.movement_speed += 100.00
		print("Speed after: ", body.movement_speed)
		
		# No bombs yet ->
		#body.bomb_range += 1
		
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
