extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
var map_size := Vector2(20, 20)

func _ready() -> void:
	# Hide the original (use it as a template)
	background_texture.visible = false

	for i in range(map_size.y):
		for j in range(map_size.x):
			var tile := background_texture.duplicate() as TextureRect
			tile.visible = true

			tile.position = Vector2(i * Config.tile_size, j * Config.tile_size)

			$Background.add_child(tile)
