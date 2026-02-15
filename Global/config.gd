extends Node

var tile_size = 64

# Game settings
var map_size := Vector2i(20, 20)
var enemy_count := 5
var difficulty := "Normal"  # Easy, Normal, Hard

# Difficulty settings
var player_hp := 3
var enemy_hp := 3
var item_drop_chance := 0.3

func _ready() -> void:
	apply_difficulty()

func apply_difficulty() -> void:
	match difficulty:
		"Easy":
			player_hp = 5
			enemy_hp = 2
			item_drop_chance = 0.5
		"Normal":
			player_hp = 3
			enemy_hp = 3
			item_drop_chance = 0.3
		"Hard":
			player_hp = 2
			enemy_hp = 4
			item_drop_chance = 0.15

func set_difficulty(diff: String) -> void:
	difficulty = diff
	apply_difficulty()
