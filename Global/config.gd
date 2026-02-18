extends Node

var tile_size = 64

# Game settings
var map_size := Vector2i(20, 20)
var enemy_count := 10
var difficulty := "Easy"  # Easy, Normal, Hard

# Difficulty settings
var player_hp := 5
var enemy_hp := 2
var item_drop_chance := 1.0

# Battle Royale Zone Settings
var toxic_zone_enabled := true
var toxic_zone_first_wave := 10.0  # Seconds before border appears
var toxic_zone_wave_interval := 5.0  # Seconds between each spread
var toxic_zone_spread_chance := 0.5  # Chance for each tile to spread (0.0-1.0)
var toxic_zone_damage := 1  # Damage per tick

func _ready() -> void:
	apply_difficulty()

func apply_difficulty() -> void:
	match difficulty:
		"Easy":
			player_hp = 5
			enemy_hp = 2
			item_drop_chance = 1.0
		"Normal":
			player_hp = 3
			enemy_hp = 3
			item_drop_chance = 0.8
		"Hard":
			player_hp = 2
			enemy_hp = 4
			item_drop_chance = 0.15

func set_difficulty(diff: String) -> void:
	difficulty = diff
	apply_difficulty()
