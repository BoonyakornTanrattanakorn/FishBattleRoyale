# see: https://kidscancode.org/godot_recipes/4.x/2d/grid_movement/index.html

extends Area2D

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var bomb_placement_system: BombPlacementSystem = $BombPlacementSystem
@onready var ray = $RayCast2D
@onready var power_up_system: Node = $PowerUpSystem

var animation_speed = 3
var moving = false

var hp = 3
var max_bombs = 1

const MAX_HP = 3

var invincible := false
var invincible_time := 1.0 # seconds


func _ready() -> void:
	position = position.snapped(Vector2.ONE * Config.tile_size)
	position += Vector2.ONE * Config.tile_size/2

func _input(_event: InputEvent) -> void:
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
	if invincible:
		return

	setHp(getHp() - 1)

	if getHp() <= 0:
		die()
	else:
		start_invincible()

func start_invincible():
	invincible = true

	# Optional blinking effect
	var tween := create_tween()
	tween.set_loops(int(invincible_time / 0.1))

	tween.tween_property(animated_sprite_2d, "modulate:a", 0.3, 0.05)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.05)

	await get_tree().create_timer(invincible_time).timeout

	invincible = false
	animated_sprite_2d.modulate.a = 1.0

func die():
	print("die")

func setHp(value: int) -> void:
	if value > MAX_HP:
		value = MAX_HP
	if value < 0:
		value = 0
	hp = value

func getHp() -> int:
	return hp

func _on_area_entered(area: Area2D) -> void:
	if area is PowerUp:
		power_up_system.enable_power_up((area as PowerUp).type)
		area.queue_free()
