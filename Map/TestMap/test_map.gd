extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var enemy_scene := preload("res://Character/Enemy/enemy.tscn")
var player_scene := preload("res://Character/Player/player.tscn")

var coral_chance := 0.5
var wall_chance := 0.1
var check_timer := 0.0
var check_interval := 1.0  # Check for win every second

# Toxic zone system
var toxic_zone: Node2D

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
	
	# Wait for physics to update before spawning enemies
	await get_tree().physics_frame
	
	# Spawn players (multiplayer or single player)
	spawn_players()
	
	# Spawn enemies based on config
	spawn_enemies()
	
	# Initialize toxic zone system
	setup_toxic_zone()


func spawn_players() -> void:
	if MultiplayerManager.is_multiplayer_active():
		# Multiplayer mode - spawn all connected players
		var spawn_positions = get_player_spawn_positions()
		var spawn_idx = 0
		
		for peer_id in MultiplayerManager.players.keys():
			if spawn_idx >= spawn_positions.size():
				break
			
			var player = player_scene.instantiate()
			player.position = spawn_positions[spawn_idx]
			player.peer_id = peer_id
			player.player_name = MultiplayerManager.get_player_name(peer_id)
			player.name = "Player_" + str(peer_id)
			add_child(player)
			
			spawn_idx += 1
			
		# Connect to multiplayer signals for late joiners
		MultiplayerManager.player_connected.connect(_on_player_connected)
		MultiplayerManager.player_disconnected.connect(_on_player_disconnected)
	else:
		# Single player mode - spawn one player
		var player = player_scene.instantiate()
		player.position = Vector2(2, 2) * Config.tile_size
		player.peer_id = 1
		player.player_name = "Player"
		player.name = "Player_1"
		add_child(player)


func get_player_spawn_positions() -> Array[Vector2]:
	# Define spawn positions in corners for up to 4 players
	var positions: Array[Vector2] = [
		Vector2(2, 2) * Config.tile_size,  # Top-left
		Vector2(Config.map_size.x - 3, 2) * Config.tile_size,  # Top-right
		Vector2(2, Config.map_size.y - 3) * Config.tile_size,  # Bottom-left
		Vector2(Config.map_size.x - 3, Config.map_size.y - 3) * Config.tile_size  # Bottom-right
	]
	return positions


func _on_player_connected(peer_id, player_info):
	print("Player joined game: ", player_info["name"])
	# Could spawn late joiners here if desired


func _on_player_disconnected(peer_id):
	print("Player left game: ", peer_id)
	# Remove disconnected player
	var player_node = get_node_or_null("Player_" + str(peer_id))
	if player_node:
		player_node.queue_free()


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
			
			# Check if position is clear (no blocks or other entities)
			var spawn_pos = Vector2(spawn_x, spawn_y) * Config.tile_size
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsPointQueryParameters2D.new()
			query.position = spawn_pos + Vector2(Config.tile_size / 2, Config.tile_size / 2)
			query.collision_mask = 1  # Check for blocks (collision layer 1)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			
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


func setup_toxic_zone() -> void:
	if not Config.toxic_zone_enabled:
		return
	
	# Load and create toxic zone system
	var ToxicZoneClass := load("res://Map/toxic_zone_system.gd")
	toxic_zone = ToxicZoneClass.new()
	toxic_zone.first_wave_delay = Config.toxic_zone_first_wave
	toxic_zone.spread_interval = Config.toxic_zone_wave_interval
	toxic_zone.spread_chance = Config.toxic_zone_spread_chance
	toxic_zone.damage_per_tick = Config.toxic_zone_damage
	
	# Connect signals for feedback
	toxic_zone.zone_advanced.connect(_on_zone_advanced)
	toxic_zone.player_in_toxic_zone.connect(_on_player_in_toxic_zone)
	
	add_child(toxic_zone)


func _on_zone_advanced(wave_number: int) -> void:
	if wave_number == 1:
		print("=== TOXIC BORDER SPAWNED ===")
	else:
		print("=== TOXIC SPREADING: Layer ", wave_number, " ===")
	print("Safe area: ", toxic_zone.get_safe_area_percentage(), "%")


func _on_player_in_toxic_zone() -> void:
	# Could add visual/audio feedback here
	pass


func check_win_condition() -> void:
	if not GameStats.game_active:
		return
	
	# Check if all enemies are dead
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		# Player wins!
		GameStats.stop_game()
		get_tree().change_scene_to_file("res://UI/game_win.tscn")
