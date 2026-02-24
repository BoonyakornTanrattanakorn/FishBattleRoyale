extends Area2D

class_name Bomb

const CENTRAL_EXPLOSION = preload("res://Bomb/center_explosion.tscn")

var explosion_size = 1

func _on_timer_timeout() -> void:
	explode()

func explode():
	var explosion = CENTRAL_EXPLOSION.instantiate()
	explosion.position = position
	explosion.size = explosion_size
	get_parent().call_deferred("add_child", explosion)
	queue_free()
