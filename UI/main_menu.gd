extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
@onready var play_button: Button = $CanvasLayer/MenuContainer/PlayButton
@onready var quit_button: Button = $CanvasLayer/MenuContainer/QuitButton

var enemy_scene := preload("res://Character/Enemy/enemy.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")

var map_size := Vector2i(20, 20)
var coral_chance := 0.2
var enemy_count := 8

func _ready() -> void:
	randomize()
	
	# Generate background
	background_texture.visible = false
	
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := background_texture.duplicate() as TextureRect
			tile.visible = true
			var pos = Vector2(x, y) * Config.tile_size
			tile.position = pos
			$Background.add_child(tile)
			
			# Border walls
			if x == 0 or x == map_size.x - 1 or y == 0 or y == map_size.y - 1:
				var wall := wall_tile.instantiate()
				wall.position = pos
				add_child(wall)
			# Interior coral
			elif randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				add_child(coral)
	
	# Spawn enemies
	spawn_enemies()
	
	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func spawn_enemies() -> void:
	for i in range(enemy_count):
		var enemy := enemy_scene.instantiate()
		
		# Find a random valid spawn position
		var valid_pos := false
		var spawn_x := 0
		var spawn_y := 0
		
		while not valid_pos:
			spawn_x = randi_range(1, map_size.x - 2)
			spawn_y = randi_range(1, map_size.y - 2)
			valid_pos = true
		
		enemy.position = Vector2(spawn_x, spawn_y) * Config.tile_size
		add_child(enemy)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/TestMap/test_map.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
