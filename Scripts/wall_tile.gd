extends StaticBody2D

class_name WallTile

var power_up_scene = preload("res://Scenes/power_up.tscn")

func destroy():
	
	if (randf() <= 0.25): # Spawning percentage
		var new_power_up = power_up_scene.instantiate()
		new_power_up.global_position = self.global_position
		get_parent().add_child(new_power_up)
		
	queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
