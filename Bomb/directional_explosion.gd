extends Area2D

class_name DirectionalExplosion

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func play_animation(animation_name: String):
	animated_sprite_2d.play(animation_name)


func _on_area_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).reduceHp()
		print("Bomb hit, HP = ", body.getHp())
