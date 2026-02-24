extends Node2D

@onready var background_texture: TextureRect = $SubViewportContainer1/SubViewport1/GameWorld/Background/BackgroundTexture
@onready var game_world: Node2D = $SubViewportContainer1/SubViewport1/GameWorld
@onready var player1: Player = $SubViewportContainer1/SubViewport1/GameWorld/Player1
@onready var player2: Player = $SubViewportContainer1/SubViewport1/GameWorld/Player2
@onready var camera1: Camera2D = $SubViewportContainer1/SubViewport1/Camera1
@onready var camera2: Camera2D = $SubViewportContainer2/SubViewport2/Camera2
@onready var viewport1: SubViewport = $SubViewportContainer1/SubViewport1
@onready var viewport2: SubViewport = $SubViewportContainer2/SubViewport2

# UI elements for Player 1
@onready var heart_container1: HBoxContainer = $SubViewportContainer1/SubViewport1/CanvasLayer1/HeartContainer1
@onready var powerup_display1: HBoxContainer = $SubViewportContainer1/SubViewport1/CanvasLayer1/PowerupDisplay1

# UI elements for Player 2
@onready var heart_container2: HBoxContainer = $SubViewportContainer2/SubViewport2/CanvasLayer2/HeartContainer2
@onready var powerup_display2: HBoxContainer = $SubViewportContainer2/SubViewport2/CanvasLayer2/PowerupDisplay2

var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var enemy_scene := preload("res://Character/Enemy/enemy.tscn")

var coral_chance := 0.5
var wall_chance := 0.1
var check_timer := 0.0
var check_interval := 1.0

# Toxic zone system
var toxic_zone: Node2D

# Track alive players
var players_alive: Array[Player] = []

func _ready() -> void:
	randomize()
	
	# Share world_2d between viewports so they see the same game world
	viewport2.world_2d = viewport1.world_2d
	
	# Start tracking game stats
	GameStats.start_game()

	background_texture.visible = false

	for y in range(Config.map_size.y):
		for x in range(Config.map_size.x):
			var tile := background_texture.duplicate() as TextureRect
			tile.visible = true

			var pos = Vector2(x, y) * Config.tile_size
			tile.position = pos

			game_world.get_node("Background").add_child(tile)

			# Border walls
			if x == 0 or x == Config.map_size.x - 1 or y == 0 or y == Config.map_size.y - 1:
				var wall := wall_tile.instantiate()
				wall.position = pos
				game_world.add_child(wall)

			# Keep Player 1 spawn area clear (top-left corner)
			elif (x >= 1 and x <= 3) and (y >= 1 and y <= 3):
				pass

			# Keep Player 2 spawn area clear (bottom-right corner)
			elif (x >= Config.map_size.x - 4 and x <= Config.map_size.x - 2) and (y >= Config.map_size.y - 4 and y <= Config.map_size.y - 2):
				pass

			# Interior tiles
			elif randf() < wall_chance:
				var wall := wall_tile.instantiate()
				wall.position = pos
				game_world.add_child(wall)
			elif randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				game_world.add_child(coral)
	
	# Setup players
	players_alive = [player1, player2]
	
	# Position players dynamically based on map size - center in tile (same as single player)
	var half_tile = Config.tile_size / 2
	player1.position = Vector2(2 * Config.tile_size + half_tile, 2 * Config.tile_size + half_tile)  # Top-left spawn - centered in tile
	player2.position = Vector2((Config.map_size.x - 3) * Config.tile_size + half_tile, (Config.map_size.y - 3) * Config.tile_size + half_tile)  # Bottom-right spawn - centered in tile
	
	# Update camera starting positions
	camera1.position = player1.position
	camera2.position = player2.position
	
	# Hide built-in CanvasLayer from players (we use our own UI)
	player1.get_node("CanvasLayer").visible = false
	player2.get_node("CanvasLayer").visible = false
	
	# Disable built-in cameras from players
	player1.get_node("Camera2D").enabled = false
	player2.get_node("Camera2D").enabled = false
	
	# Setup UI connections for Player 1
	heart_container1.setMaxHearts(Config.player_hp)
	heart_container1.updateHearts(player1.get_hp())
	player1.healthChanged.connect(heart_container1.updateHearts)
	player1.power_up_system.powerups_changed.connect(powerup_display1.update_display)
	
	# Setup UI connections for Player 2
	heart_container2.setMaxHearts(Config.player_hp)
	heart_container2.updateHearts(player2.get_hp())
	player2.healthChanged.connect(heart_container2.updateHearts)
	player2.power_up_system.powerups_changed.connect(powerup_display2.update_display)
	
	# Connect death signals
	player1.player_died.connect(_on_player_died)
	player2.player_died.connect(_on_player_died)
	
	# Wait for physics to update before spawning enemies
	await get_tree().physics_frame
	
	# Spawn enemies based on config
	spawn_enemies()
	
	# Initialize toxic zone system
	setup_toxic_zone()


func _process(delta: float) -> void:
	# Update cameras to follow players (round to prevent sub-pixel rendering artifacts)
	if player1 and not player1.is_dead:
		camera1.position = player1.position.round()
	if player2 and not player2.is_dead:
		camera2.position = player2.position.round()
	
	# Check for win condition periodically
	check_timer += delta
	if check_timer >= check_interval:
		check_timer = 0.0
		check_win_condition()


func _on_player_died(player_id: int) -> void:
	# Remove dead player from alive list
	players_alive = players_alive.filter(func(p): return not p.is_dead)
	
	# Check if only one player remains
	if players_alive.size() == 1:
		var winner = players_alive[0]
		print("Player ", winner.player_id, " wins!")
		GameStats.stop_game()
		# Store winner for display
		GameStats.winner_id = winner.player_id
		get_tree().change_scene_to_file("res://UI/game_win.tscn")
	elif players_alive.size() == 0:
		# Both died at same time - draw
		print("Draw!")
		GameStats.stop_game()
		get_tree().change_scene_to_file("res://UI/game_over.tscn")


func spawn_enemies() -> void:
	for i in range(Config.enemy_count):
		var enemy := enemy_scene.instantiate()
		
		var spawn_x: int
		var spawn_y: int
		var attempts := 0
		const MAX_ATTEMPTS := 100
		
		while attempts < MAX_ATTEMPTS:
			spawn_x = randi_range(2, Config.map_size.x - 3)
			spawn_y = randi_range(2, Config.map_size.y - 3)
			
			# Avoid Player 1 spawn area (top-left)
			if (spawn_x >= 1 and spawn_x <= 3) and (spawn_y >= 1 and spawn_y <= 3):
				attempts += 1
				continue
			
			# Avoid Player 2 spawn area (bottom-right)
			if (spawn_x >= Config.map_size.x - 4 and spawn_x <= Config.map_size.x - 2) and (spawn_y >= Config.map_size.y - 4 and spawn_y <= Config.map_size.y - 2):
				attempts += 1
				continue
			
			var spawn_pos = Vector2(spawn_x, spawn_y) * Config.tile_size
			var space_state := viewport1.world_2d.direct_space_state
			var query := PhysicsPointQueryParameters2D.new()
			query.position = spawn_pos + Vector2(Config.tile_size / 2, Config.tile_size / 2)
			query.collision_mask = 1
			query.collide_with_areas = false
			query.collide_with_bodies = true
			
			var result := space_state.intersect_point(query)
			if result.is_empty():
				enemy.position = spawn_pos
				game_world.add_child(enemy)
				break
			
			attempts += 1


func setup_toxic_zone() -> void:
	if not Config.toxic_zone_enabled:
		return
	
	var ToxicZoneClass := load("res://Map/toxic_zone_system.gd")
	toxic_zone = ToxicZoneClass.new()
	toxic_zone.first_wave_delay = Config.toxic_zone_first_wave
	toxic_zone.spread_interval = Config.toxic_zone_wave_interval
	toxic_zone.spread_chance = Config.toxic_zone_spread_chance
	toxic_zone.damage_per_tick = Config.toxic_zone_damage
	
	toxic_zone.zone_advanced.connect(_on_zone_advanced)
	toxic_zone.player_in_toxic_zone.connect(_on_player_in_toxic_zone)
	
	game_world.add_child(toxic_zone)


func _on_zone_advanced(wave_number: int) -> void:
	if wave_number == 1:
		print("=== TOXIC BORDER SPAWNED ===")
	else:
		print("=== TOXIC SPREADING: Layer ", wave_number, " ===")
	print("Safe area: ", toxic_zone.get_safe_area_percentage(), "%")


func _on_player_in_toxic_zone() -> void:
	pass


func check_win_condition() -> void:
	if not GameStats.game_active:
		return
	
	# In multiplayer, win when enemies are dead and only 1 player remains
	# Or just check if all enemies are dead for coop mode
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0 and players_alive.size() > 0:
		GameStats.stop_game()
		get_tree().change_scene_to_file("res://UI/game_win.tscn")
