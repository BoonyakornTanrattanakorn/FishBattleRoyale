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

func _ready() -> void:
	position = position.snapped(Vector2.ONE * Config.tile_size)
	position += Vector2.ONE * Config.tile_size/2

func _input(_event: InputEvent) -> void:
	if moving:
		return
		
	if Input.is_action_just_pressed("Right"):
		move(Vector2.RIGHT)
		animated_sprite_2d.flip_h = false
	elif Input.is_action_just_pressed("Left"):
		move(Vector2.LEFT)
		animated_sprite_2d.flip_h = true
	elif Input.is_action_just_pressed("Up"):
		move(Vector2.UP)
	elif Input.is_action_just_pressed("Down"):
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
	if getHp() <= 0:
		die()

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
