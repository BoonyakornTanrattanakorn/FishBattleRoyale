extends Area2D
class_name Character

@onready var ray: RayCast2D = $RayCast2D

var animation_speed := 3.0
var moving := false

var hp := 3
const MAX_HP := 3

var invincible := false
var invincible_time := 1.0

var max_bombs := 1


func _ready():
	position = position.snapped(Vector2.ONE * Config.tile_size)
	position += Vector2.ONE * Config.tile_size / 2


func move(dir: Vector2) -> void:
	if moving:
		return

	ray.target_position = dir * Config.tile_size
	ray.force_raycast_update()

	if ray.is_colliding():
		return

	var tween := create_tween()
	tween.tween_property(
		self,
		"position",
		position + dir * Config.tile_size,
		1.0 / animation_speed
	)

	moving = true
	await tween.finished
	moving = false


# ---------------- HP SYSTEM ----------------

func reduce_hp():
	if invincible:
		return

	set_hp(hp - 1)

	if hp <= 0:
		die()
	else:
		start_invincible()


func start_invincible():
	invincible = true
	await get_tree().create_timer(invincible_time).timeout
	invincible = false


func die():
	queue_free()


func set_hp(value: int):
	hp = clamp(value, 0, MAX_HP)


func get_hp() -> int:
	return hp
