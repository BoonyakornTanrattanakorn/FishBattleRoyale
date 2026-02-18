extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
@onready var single_player: Node = $Player  # Reference to single player in scene
var player_scene := preload("res://Character/Player/player.tscn")
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var enemy_scene := preload("res://Character/Enemy/enemy.tscn")

var coral_chance := 0.5
var wall_chance := 0.1
var check_timer := 0.0
var check_interval := 1.0  # Check for win every second

# Toxic zone system
var toxic_zone: Node2D

# Multiplayer tracking
var spawn_positions := []
var next_spawn_index := 0
var spawned_players := {}
var map_seed := 0
var map_generated := false

# Server's config values for consistent map generation and gameplay
var server_config := {}

func _ready() -> void:
	# Check if player died - prevent rejoining
	if GameStats.player_died:
		print("Player already died - cannot rejoin")
		get_tree().change_scene_to_file("res://UI/game_over.tscn")
		return
	
	# Start tracking game stats
	GameStats.start_game()
	GameStats.set_multiplayer_session(NetworkManager.is_multiplayer())
	
	# Handle multiplayer seed synchronization
	if NetworkManager.is_multiplayer():
		if multiplayer.is_server():
			# Server generates the seed and stores all config values
			map_seed = randi()
			server_config = {
				"map_size": Config.map_size,
				"tile_size": Config.tile_size,
				"enemy_count": Config.enemy_count,
				"player_hp": Config.player_hp,
				"enemy_hp": Config.enemy_hp,
				"item_drop_chance": Config.item_drop_chance,
				"toxic_zone_enabled": Config.toxic_zone_enabled,
				"toxic_zone_first_wave": Config.toxic_zone_first_wave,
				"toxic_zone_wave_interval": Config.toxic_zone_wave_interval,
				"toxic_zone_spread_chance": Config.toxic_zone_spread_chance,
				"toxic_zone_damage": Config.toxic_zone_damage,
			}
			print("Server generated map seed: ", map_seed)
			print("Server config: ", server_config)
			# Generate map immediately on server
			seed(map_seed)
			generate_map()
		else:
			# Client requests seed and config from server once ready
			print("Client requesting map seed and config from server...")
			_request_map_seed.rpc_id(1)
	else:
		# Single player - use random seed
		randomize()
		generate_map()


# Client requests the map seed and config from server
@rpc("any_peer", "call_remote", "reliable")
func _request_map_seed() -> void:
	if not multiplayer.is_server():
		return
	
	var peer_id = multiplayer.get_remote_sender_id()
	print("Server sending map seed and config to client ", peer_id)
	# Send seed and all config values to the requesting client
	_receive_map_seed.rpc_id(peer_id, map_seed, server_config)


# Server sends the map seed and all config values to a specific client
@rpc("authority", "call_remote", "reliable")
func _receive_map_seed(synced_seed: int, synced_config: Dictionary) -> void:
	print("Client received map seed: ", synced_seed)
	print("Client received server config: ", synced_config)
	
	# Store server's config
	map_seed = synced_seed
	server_config = synced_config
	
	# Override local config with server's config for consistent gameplay
	Config.map_size = server_config["map_size"]
	Config.tile_size = server_config["tile_size"]
	Config.enemy_count = server_config["enemy_count"]
	Config.player_hp = server_config["player_hp"]
	Config.enemy_hp = server_config["enemy_hp"]
	Config.item_drop_chance = server_config["item_drop_chance"]
	Config.toxic_zone_enabled = server_config["toxic_zone_enabled"]
	Config.toxic_zone_first_wave = server_config["toxic_zone_first_wave"]
	Config.toxic_zone_wave_interval = server_config["toxic_zone_wave_interval"]
	Config.toxic_zone_spread_chance = server_config["toxic_zone_spread_chance"]
	Config.toxic_zone_damage = server_config["toxic_zone_damage"]
	
	seed(map_seed)
	generate_map()


func generate_map() -> void:
	if map_generated:
		return
	
	map_generated = true
	print("Generating map with seed: ", map_seed if map_seed != 0 else "random")

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

			# ---- Keep all player spawn corners clear (3x3 safe zones) ----
			elif ((x >= 1 and x <= 3) and (y >= 1 and y <= 3)) or \
				 ((x >= Config.map_size.x - 4 and x <= Config.map_size.x - 2) and (y >= 1 and y <= 3)) or \
				 ((x >= 1 and x <= 3) and (y >= Config.map_size.y - 4 and y <= Config.map_size.y - 2)) or \
				 ((x >= Config.map_size.x - 4 and x <= Config.map_size.x - 2) and (y >= Config.map_size.y - 4 and y <= Config.map_size.y - 2)):
				# Keep spawn areas clear - no walls or coral
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
	
	# Wait for physics to update before spawning content
	await get_tree().physics_frame
	
	# Define spawn positions for multiplayer
	spawn_positions = [
		Vector2(1, 1) * Config.tile_size,  # Top-left
		Vector2(Config.map_size.x - 2, 1) * Config.tile_size,  # Top-right
		Vector2(1, Config.map_size.y - 2) * Config.tile_size,  # Bottom-left
		Vector2(Config.map_size.x - 2, Config.map_size.y - 2) * Config.tile_size,  # Bottom-right
	]
	
	# Setup players for multiplayer or single player
	setup_players()
	
	# Spawn enemies based on config
	spawn_enemies()
	
	# Initialize toxic zone system
	setup_toxic_zone()
	
	print("Map generation complete!")


func setup_players() -> void:
	if NetworkManager.is_multiplayer():
		# Remove the single player instance
		if single_player:
			single_player.queue_free()
		
		# Connect to multiplayer signals for dynamic spawning
		if not multiplayer.peer_connected.is_connected(_on_player_connected):
			multiplayer.peer_connected.connect(_on_player_connected)
		
		# Only server spawns players
		if multiplayer.is_server():
			# Spawn host player
			spawn_player(1)
			
			# Spawn any already connected peers
			for peer_id in multiplayer.get_peers():
				spawn_player(peer_id)
		else:
			# Client: request spawn from server
			request_spawn.rpc_id(1, multiplayer.get_unique_id())
	else:
		# Single player mode - player already in scene
		if single_player:
			print("Single player mode")


func _on_player_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		print("Player connected: ", peer_id)
		spawn_player(peer_id)


func spawn_player(peer_id: int) -> void:
	if spawned_players.has(peer_id):
		return  # Already spawned
	
	var spawn_pos = spawn_positions[next_spawn_index % spawn_positions.size()]
	next_spawn_index += 1
	
	print("Server: Spawning player ", peer_id, " at ", spawn_pos)
	
	# Spawn locally on server
	var player := player_scene.instantiate()
	player.peer_id = peer_id
	player.name = "Player_%d" % peer_id
	player.position = spawn_pos
	
	# Set multiplayer authority before adding to tree
	player.set_multiplayer_authority(peer_id)
	
	add_child(player)
	
	spawned_players[peer_id] = player
	
	# Tell all clients to spawn this player
	spawn_player_on_clients.rpc(peer_id, spawn_pos)


@rpc("any_peer", "call_local", "reliable")
func request_spawn(peer_id: int) -> void:
	if multiplayer.is_server():
		spawn_player(peer_id)


@rpc("authority", "call_local", "reliable")
func spawn_player_on_clients(peer_id: int, spawn_pos: Vector2) -> void:
	# Skip if we're the server (already spawned locally)
	if multiplayer.is_server():
		return
	
	if spawned_players.has(peer_id):
		return  # Already spawned
	
	print("Client: Spawning player ", peer_id, " at ", spawn_pos)
	
	var player := player_scene.instantiate()
	player.peer_id = peer_id
	player.name = "Player_%d" % peer_id
	player.position = spawn_pos
	
	# Set multiplayer authority before adding to tree
	player.set_multiplayer_authority(peer_id)
	
	add_child(player)
	
	spawned_players[peer_id] = player


func spawn_enemies() -> void:
	for i in range(Config.enemy_count):
		var enemy := enemy_scene.instantiate()
		
		# Set unique name for multiplayer synchronization
		enemy.name = "Enemy_" + str(i)
		
		# Find a random valid spawn position (avoid player spawn areas)
		var spawn_x: int
		var spawn_y: int
		var attempts := 0
		const MAX_ATTEMPTS := 100
		
		# Keep trying until we find a clear spot
		while attempts < MAX_ATTEMPTS:
			spawn_x = randi_range(3, Config.map_size.x - 4)
			spawn_y = randi_range(3, Config.map_size.y - 4)
			
			# Avoid all corner spawn areas (3x3 safe zones)
			var in_top_left := (spawn_x >= 1 and spawn_x <= 3) and (spawn_y >= 1 and spawn_y <= 3)
			var in_top_right := (spawn_x >= Config.map_size.x - 4 and spawn_x <= Config.map_size.x - 2) and (spawn_y >= 1 and spawn_y <= 3)
			var in_bottom_left := (spawn_x >= 1 and spawn_x <= 3) and (spawn_y >= Config.map_size.y - 4 and spawn_y <= Config.map_size.y - 2)
			var in_bottom_right := (spawn_x >= Config.map_size.x - 4 and spawn_x <= Config.map_size.x - 2) and (spawn_y >= Config.map_size.y - 4 and spawn_y <= Config.map_size.y - 2)
			
			if in_top_left or in_top_right or in_bottom_left or in_bottom_right:
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
				# Connect enemy death signal for multiplayer sync
				if NetworkManager.is_multiplayer():
					enemy.enemy_died.connect(_on_enemy_died)
				add_child(enemy)
				break
			
			attempts += 1


# Handle enemy death synchronization in multiplayer
func _on_enemy_died(enemy_name: String) -> void:
	if NetworkManager.is_multiplayer():
		# Notify all clients to remove this enemy
		_remove_enemy.rpc(enemy_name)


@rpc("any_peer", "call_local", "reliable")
func _remove_enemy(enemy_name: String) -> void:
	var enemy = get_node_or_null(enemy_name)
	if enemy:
		print("Removing enemy: ", enemy_name)
		enemy.queue_free()


func _process(delta: float) -> void:
	# Only server checks win condition to prevent desync
	if NetworkManager.is_multiplayer() and not multiplayer.is_server():
		return
	
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
	
	# Check enemy count first
	var enemies := get_tree().get_nodes_in_group("enemies")
	var all_enemies_dead := enemies.size() == 0
	
	# In multiplayer, must be last player alive AND all enemies dead
	if NetworkManager.is_multiplayer():
		var players := get_tree().get_nodes_in_group("player")
		var alive_players := 0
		var winning_player: Player = null
		
		for player in players:
			if player is Player and not player.is_dead:
				alive_players += 1
				winning_player = player
		
		# Win condition: Only 1 player alive AND all enemies dead
		if alive_players == 1 and winning_player and all_enemies_dead:
			# Server tells the winning player to show win screen
			print("Win condition met - winner: ", winning_player.player_name)
			_show_win_screen.rpc_id(winning_player.peer_id)
		# All players dead = no winner (shouldn't happen with spectator mode)
		elif alive_players == 0:
			print("All players dead - game over")
	else:
		# Single player: Check if all enemies are dead
		if all_enemies_dead:
			# Player wins!
			GameStats.stop_game()
			get_tree().change_scene_to_file("res://UI/game_win.tscn")


@rpc("authority", "call_remote", "reliable")
func _show_win_screen() -> void:
	# Called by server to show win screen on the winning client
	GameStats.stop_game()
	get_tree().change_scene_to_file("res://UI/game_win.tscn")
