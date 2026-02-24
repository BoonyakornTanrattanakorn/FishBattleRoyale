extends Area2D

class_name PowerUp

@onready var sprite_2d: Sprite2D = $Sprite2D

var type: Utils.PowerUpType

func init(power_up_res: PowerUpRes):
	sprite_2d.texture = power_up_res.texture
	type = power_up_res.type
	
	# Scale up HP icon since it's smaller than other power-ups
	if type == Utils.PowerUpType.HP:
		sprite_2d.scale = Vector2(2, 2)
	elif type == Utils.PowerUpType.SPEED_UP:
		sprite_2d.scale = Vector2(1.5, 1.5)
		
