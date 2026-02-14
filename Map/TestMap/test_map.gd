extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")

var map_size := Vector2i(20, 20)
var coral_chance := 0.3

func _ready() -> void:
	randomize()

	background_texture.visible = false

	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := background_texture.duplicate() as TextureRect
			tile.visible = true

			var pos = Vector2(x, y) * Config.tile_size
			tile.position = pos

			$Background.add_child(tile)

			# ---- Border walls ----
			if x == 0 or x == map_size.x - 1 or y == 0 or y == map_size.y - 1:
				var wall := wall_tile.instantiate()
				wall.position = pos
				add_child(wall)

			# ---- Interior coral ----
			elif randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				add_child(coral)
