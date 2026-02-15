extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var enemy_scene := preload("res://Character/Enemy/enemy.tscn")

var coral_chance := 0.3
var check_timer := 0.0
var check_interval := 1.0  # Check for win every second

func _ready() -> void:
	randomize()
	
	# Start tracking game stats
	GameStats.start_game()

	background_texture.visible = false

	for y in range(Config.map_size.y):
		for x in range(Config.map_size.x):
			var tile := background_texture.duplicate() as TextureRect
			tile.visible = true

			var pos = Vector2(x, y) * Config.tile_size
			tile.position = pos

			$Background.add_child(tile)

			# ---- Border walls ----
			if x == 0 or x == Config.map_size.x - 1 or y == 0 or y == Config.map_size.y - 1:
				var wall := wall_tile.instantiate()
				wall.position = pos
				add_child(wall)

			# ---- Interior coral ----
			elif randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				add_child(coral)
	
	# Spawn enemies based on config
	spawn_enemies()


func spawn_enemies() -> void:
	for i in range(Config.enemy_count):
		var enemy := enemy_scene.instantiate()
		
		# Find a random valid spawn position
		var spawn_x := randi_range(2, Config.map_size.x - 3)
		var spawn_y := randi_range(2, Config.map_size.y - 3)
		
		enemy.position = Vector2(spawn_x, spawn_y) * Config.tile_size
		add_child(enemy)


func _process(delta: float) -> void:
	# Check for win condition periodically
	check_timer += delta
	if check_timer >= check_interval:
		check_timer = 0.0
		check_win_condition()


func check_win_condition() -> void:
	if not GameStats.game_active:
		return
	
	# Check if all enemies are dead
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		# Player wins!
		GameStats.stop_game()
		get_tree().change_scene_to_file("res://UI/game_win.tscn")
