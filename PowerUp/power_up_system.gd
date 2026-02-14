extends Node

class_name PowerUpSystem

var player: Player

@onready var bomb_placement_system: BombPlacementSystem = $"../BombPlacementSystem"
@onready var speed_up_timer: Timer = $SpeedUpTimer

const SPEED_MOD = 50

func _ready() -> void:
	player = get_parent()
	
func enable_power_up(power_up_type: Utils.PowerUpType):
	match power_up_type:
		Utils.PowerUpType.BOMB_UP:
			player.max_bombs += 1
			print("bomb_up")
		Utils.PowerUpType.FIRE_UP:
			bomb_placement_system.explosion_size += 1
			print("fire_up")
		Utils.PowerUpType.SPEED_UP:
			# player.movement_speed += SPEED_MOD
			print("speed_up_start")
			speed_up_timer.start()

func _on_speed_up_timer_timeout() -> void:
	print("speed_up_end")
	# player.movement_speed -= SPEED_MOD
