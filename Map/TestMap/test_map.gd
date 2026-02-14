extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")

var map_size := Vector2i(20, 20)
var coral_chance := 0.3 # 30%

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

			# ---- Spawn coral randomly ----
			if randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				add_child(coral)
