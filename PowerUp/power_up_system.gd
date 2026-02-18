extends Node

class_name PowerUpSystem

signal powerups_changed(bomb_ups: int, fire_ups: int, speed_ups: int)

var character: Character

@onready var bomb_placement_system: BombPlacementSystem = $"../BombPlacementSystem"
@onready var speed_up_timer: Timer = $SpeedUpTimer

const SPEED_MOD = 2.0

# Track powerup counts
var bomb_ups := 0
var fire_ups := 0
var speed_ups := 0

func _ready() -> void:
	character = get_parent()
	
func enable_power_up(power_up_type: Utils.PowerUpType):
	match power_up_type:
		Utils.PowerUpType.BOMB_UP:
			character.max_bombs += 1
			bomb_ups += 1
			print("bomb_up")
		Utils.PowerUpType.FIRE_UP:
			bomb_placement_system.explosion_size += 1
			fire_ups += 1
			print("fire_up")
		Utils.PowerUpType.SPEED_UP:
			character.animation_speed += SPEED_MOD
			speed_ups += 1
			print("speed_up_start")
			speed_up_timer.start()
		Utils.PowerUpType.HP:
			# Heal character by 1 HP (up to max_hp)
			character.set_hp(character.get_hp() + 1)
			# Update health UI for player
			if character is Player:
				character.healthChanged.emit(character.get_hp())
			print("hp_restored")
	
	# Emit signal to update UI
	powerups_changed.emit(bomb_ups, fire_ups, speed_ups)

func _on_speed_up_timer_timeout() -> void:
	print("speed_up_end")
	character.animation_speed -= SPEED_MOD
