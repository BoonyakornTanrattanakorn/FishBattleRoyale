extends Character
class_name Player

signal healthChanged

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var bomb_placement_system: BombPlacementSystem = $BombPlacementSystem
@onready var power_up_system: Node = $PowerUpSystem


func _input(_event):
	if moving:
		return

	if Input.is_action_pressed("Right"):
		move(Vector2.RIGHT)
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed("Left"):
		move(Vector2.LEFT)
		animated_sprite_2d.flip_h = true
	elif Input.is_action_pressed("Up"):
		move(Vector2.UP)
	elif Input.is_action_pressed("Down"):
		move(Vector2.DOWN)

	if Input.is_action_just_pressed("PlaceBomb"):
		bomb_placement_system.place_bomb()

func move(dir):
	ray.target_position = dir * Config.tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "position",
			position + dir * Config.tile_size, 1.0/animation_speed).set_trans(Tween.TRANS_SINE)
		moving = true
		await tween.finished
		moving = false
		
func reduceHp():
	setHp(getHp()-1)
	healthChanged.emit(hp)
	if getHp() <= 0:
		die()

# Override invincible for blinking
func start_invincible():
	invincible = true

	var tween := create_tween()
	tween.set_loops(int(invincible_time / 0.1))
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.3, 0.05)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.05)

	await get_tree().create_timer(invincible_time).timeout

	invincible = false
	animated_sprite_2d.modulate.a = 1.0


func die():
	print("player died")


func _on_area_entered(area: Area2D):
	if area is PowerUp:
		power_up_system.enable_power_up(area.type)
		area.queue_free()
