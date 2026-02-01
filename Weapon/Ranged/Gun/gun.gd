extends Node2D

@export var bullet_scene: PackedScene
@export var muzzle_distance := 40.0
const SPRITE_ROT_OFFSET := 0.0

func _process(delta: float) -> void:
	var dir = get_global_mouse_position() - global_position
	rotation = dir.angle() + SPRITE_ROT_OFFSET

	if Input.is_action_just_pressed("shoot"):
		shoot(dir.normalized())

	queue_redraw()

func shoot(direction: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	
	bullet.global_position = global_position + direction * muzzle_distance
	bullet.rotation = direction.angle()
	bullet.velocity = direction * bullet.speed

	get_tree().current_scene.add_child(bullet)
	print(get_tree().current_scene)

func _draw() -> void:
	var dir = to_local(get_global_mouse_position())
	draw_line(Vector2.ZERO, dir.normalized() * 100, Color.RED, 2.0)
