extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var enemy_scene := preload("res://Character/Enemy/enemy.tscn")

var coral_chance := 0.3
var wall_chance := 0.15
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

			# ---- Keep player spawn area clear (top-left corner) ----
			elif (x >= 1 and x <= 3) and (y >= 1 and y <= 3):
				# Keep spawn area clear - no walls or coral
				pass

			# ---- Interior tiles ----
			elif randf() < wall_chance:
				var wall := wall_tile.instantiate()
				wall.position = pos
				add_child(wall)
			elif randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				add_child(coral)
	
	# Spawn enemies based on config
	spawn_enemies()


func spawn_enemies() -> void:
	for i in range(Config.enemy_count):
		var enemy := enemy_scene.instantiate()
		
		# Find a random valid spawn position (avoid player spawn area)
		var spawn_x: int
		var spawn_y: int
		var attempts := 0
		const MAX_ATTEMPTS := 100
		
		# Keep trying until we find a clear spot
		while attempts < MAX_ATTEMPTS:
			spawn_x = randi_range(2, Config.map_size.x - 3)
			spawn_y = randi_range(2, Config.map_size.y - 3)
			
			# Avoid player spawn area (top-left)
			if (spawn_x >= 1 and spawn_x <= 3) and (spawn_y >= 1 and spawn_y <= 3):
				attempts += 1
				continue
			
			# Check if position is clear (no blocks)
			var spawn_pos = Vector2(spawn_x, spawn_y) * Config.tile_size
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsPointQueryParameters2D.new()
			query.position = spawn_pos + Vector2(Config.tile_size / 2, Config.tile_size / 2)
			query.collision_mask = 1  # Check for blocks
			
			var result := space_state.intersect_point(query)
			if result.is_empty():
				# Position is clear
				enemy.position = spawn_pos
				add_child(enemy)
				break
			
			attempts += 1


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
