extends StaticBody2D

class_name BrickWall

const POWER_UP_SCENE = preload("res://Scenes/power_up.tscn")

@export var bomb_up_res: PowerUpRes
@export var fire_up_res: PowerUpRes
@export var speed_up_res: PowerUpRes

func destroy():
	
	if (randf() <= 0.25): # Spawning percentage
		spawn_power_up()
		
	queue_free()

func spawn_power_up():
	var new_power_up = POWER_UP_SCENE.instantiate()
	new_power_up.global_position = global_position
	get_parent().add_child(new_power_up)
	if (randf() <= 0.33):
		new_power_up.init(bomb_up_res)
	elif (randf() <= 0.67):
		new_power_up.init(fire_up_res)
	else:
		new_power_up.init(speed_up_res)
		
