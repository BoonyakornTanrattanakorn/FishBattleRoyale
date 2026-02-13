extends StaticBody2D

class_name BrickWall

const POWER_UP_SCENE = preload("res://PowerUp/power_up.tscn")

@export var bomb_up_res: PowerUpRes
@export var fire_up_res: PowerUpRes
@export var speed_up_res: PowerUpRes

func destroy():
	
	if (randf() <= 0.35): # Spawning percentage
		spawn_power_up()
		
	queue_free()

func spawn_power_up():
	var new_power_up = POWER_UP_SCENE.instantiate()
	new_power_up.global_position = global_position
	get_parent().add_child(new_power_up)
	
	var indicator = randf()
	if (indicator <= 0.35):
		new_power_up.init(bomb_up_res)
	elif (indicator <= 0.70):
		new_power_up.init(fire_up_res)
	else:
		new_power_up.init(speed_up_res)
		
