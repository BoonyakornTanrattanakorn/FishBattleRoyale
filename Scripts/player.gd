extends Area2D

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var bomb_placement_system: BombPlacementSystem = $BombPlacementSystem
@onready var raycasts: Raycasts = $RayCasts
@onready var power_up_system: Node = $PowerUpSystem

@export var movement_speed: float = 200

var hp = 3
var max_bombs = 1
var movement: Vector2 = Vector2.ZERO

const MAX_HP = 3

func _process(delta: float) -> void:
	var collision = raycasts.check_collisions()
	
	if collision.has(movement):
		return
	position += movement * delta * movement_speed

func _input(_event: InputEvent) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
		
	if Input.is_action_pressed("Right"):
		movement = Vector2.RIGHT
	elif Input.is_action_pressed("Left"):
		movement = Vector2.LEFT
	elif Input.is_action_pressed("Up"):
		movement = Vector2.UP
	elif Input.is_action_pressed("Down"):
		movement = Vector2.DOWN
	else:
		movement = Vector2.ZERO
	
	if Input.is_action_just_pressed("PlaceBomb"):
		bomb_placement_system.place_bomb()
		

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
