extends Node2D
class_name ToxicZoneSystem

## Battle Royale zone system that shrinks the playable area with toxic coral growth
## Grows inward from borders in creative wave patterns instead of boring circles

signal zone_advanced(wave_number: int)
signal player_in_toxic_zone

# Configuration
@export var enabled := true
@export var first_wave_delay := 30.0  # Seconds before first wave starts
@export var spread_interval := 2.0  # Seconds between each spread step
@export_range(0.0, 1.0) var spread_chance := 0.5  # Probability each adjacent tile spreads (0.0-1.0)
@export var damage_interval := 1.0  # How often to damage players in toxic zone
@export var damage_per_tick := 1  # Damage dealt per interval

# Internal state
var current_wave := 0
var spread_timer := 0.0
var damage_timer := 0.0
var toxic_tiles := {}  # Dictionary of toxic tile positions
var game_started := false
var spreading_active := false  # Whether toxic zone is currently spreading

# UI reference (optional)
var ui_label: Node = null

# Colors
const TOXIC_COLOR := Color(0.5, 0.0, 0.8, 0.8)  # Purple toxic color (increased opacity)


func _ready() -> void:
	if not enabled:
		return
	
	# Add to group so enemies can find us
	add_to_group("toxic_zone")
	
	# Wait a frame for the map to be fully loaded
	await get_tree().process_frame
	start_system()


func start_system() -> void:
	game_started = true
	spread_timer = first_wave_delay
	print("Toxic Zone System: Started! Toxic zone will appear in ", first_wave_delay, " seconds")


func _process(delta: float) -> void:
	if not enabled or not game_started:
		return
	
	# Initial spawn or spreading timer
	if not spreading_active:
		spread_timer -= delta
		
		# Update UI countdown
		if ui_label and ui_label.has_method("show_countdown") and spread_timer > 0:
			if spread_timer <= 10.0:  # Show countdown in last 10 seconds
				ui_label.show_countdown(spread_timer)
		
		if spread_timer <= 0:
			if toxic_tiles.is_empty():
				# First time - spawn border tiles
				spawn_initial_border()
			spreading_active = true
			spread_timer = spread_interval
	else:
		# Spreading phase - gradually expand inward
		spread_timer -= delta
		if spread_timer <= 0:
			spread_to_adjacent()
			spread_timer = spread_interval
	
	# Damage timer
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		check_player_damage()


func spawn_initial_border() -> void:
	print("=== SPAWNING INITIAL TOXIC BORDER ===")
	var border_positions := get_border_positions()
	
	# Randomly select only 10% of border tiles
	border_positions.shuffle()
	var spawn_count: int = max(1, int(border_positions.size() * 0.1))  # At least 1 tile
	var selected_positions := border_positions.slice(0, spawn_count)
	
	for pos in selected_positions:
		create_toxic_tile(pos)
	
	current_wave = 1
	zone_advanced.emit(current_wave)
	print("Toxic Zone: Border spawned with ", selected_positions.size(), " tiles (10% of ", border_positions.size(), " border tiles)")
	
	# Update UI
	if ui_label and ui_label.has_method("set_wave"):
		ui_label.set_wave(current_wave)
		ui_label.set_safe_percentage(get_safe_area_percentage())


func get_border_positions() -> Array:
	var positions := []
	var map_width := Config.map_size.x
	var map_height := Config.map_size.y
	
	# Get all border tiles (outer edge)
	for x in range(map_width):
		for y in range(map_height):
			if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
				positions.append(Vector2i(x, y))
	
	return positions


func spread_to_adjacent() -> void:
	# Find all tiles adjacent to current toxic tiles
	var new_toxic_positions := []
	var checked := {}  # Avoid duplicates
	
	for toxic_pos in toxic_tiles.keys():
		# Check all 4 adjacent positions (up, down, left, right)
		var adjacent := [
			toxic_pos + Vector2i(0, -1),  # Up
			toxic_pos + Vector2i(0, 1),   # Down
			toxic_pos + Vector2i(-1, 0),  # Left
			toxic_pos + Vector2i(1, 0)    # Right
		]
		
		for adj_pos in adjacent:
			# Check if position is valid and not already toxic
			if is_position_valid(adj_pos) and not is_tile_toxic(adj_pos) and not checked.has(adj_pos):
				# Probabilistic spreading - use spread_chance
				if randf() <= spread_chance:
					new_toxic_positions.append(adj_pos)
				checked[adj_pos] = true
	
	if new_toxic_positions.is_empty():
		print("Toxic Zone: Spreading complete - entire map covered!")
		spreading_active = false
		return
	
	print("=== TOXIC SPREADING: ", new_toxic_positions.size(), " new tiles ===")
	
	# Create new toxic tiles
	for pos in new_toxic_positions:
		create_toxic_tile(pos)
	
	current_wave += 1
	zone_advanced.emit(current_wave)
	
	# Update UI
	if ui_label and ui_label.has_method("set_wave"):
		ui_label.set_wave(current_wave)
		ui_label.set_safe_percentage(get_safe_area_percentage())


func is_position_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < Config.map_size.x and pos.y >= 0 and pos.y < Config.map_size.y


func advance_wave() -> void:
	# This function is no longer used with the spreading system
	# Kept for compatibility
	pass


func create_toxic_tile(grid_pos: Vector2i) -> void:
	if is_tile_toxic(grid_pos):
		return
	
	# Create visual indicator using Polygon2D (not ColorRect - that's for UI!)
	var tile := Polygon2D.new()
	var tile_size := float(Config.tile_size)
	
	# Create a square polygon
	tile.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(tile_size, 0),
		Vector2(tile_size, tile_size),
		Vector2(0, tile_size)
	])
	
	tile.position = Vector2(grid_pos) * Config.tile_size
	tile.color = TOXIC_COLOR
	tile.z_index = 10  # Above background and blocks, below characters
	
	add_child(tile)
	toxic_tiles[grid_pos] = tile
	
	print("Created toxic tile at grid ", grid_pos, " world pos ", tile.position)
	
	# Add pulsing animation - must be added after tile is in tree
	var tween := tile.create_tween()
	tween.set_loops(0)  # 0 means infinite loops in Godot 4
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "color:a", 0.5, 1.0)
	tween.tween_property(tile, "color:a", 0.9, 1.0)


func is_tile_toxic(grid_pos: Vector2i) -> bool:
	return toxic_tiles.has(grid_pos)


func is_position_toxic(world_pos: Vector2) -> bool:
	var grid_pos := Vector2i(world_pos / Config.tile_size)
	return is_tile_toxic(grid_pos)


func check_player_damage() -> void:
	# Check both players and enemies
	var players := get_tree().get_nodes_in_group("player")
	var enemies := get_tree().get_nodes_in_group("enemies")
	
	for player in players:
		if player.has_method("reduce_hp") and is_position_toxic(player.position):
			player.reduce_hp()
			player_in_toxic_zone.emit()
			print("Player taking toxic damage!")
	
	for enemy in enemies:
		if enemy.has_method("reduce_hp") and is_position_toxic(enemy.position):
			enemy.reduce_hp()
			print("Enemy taking toxic damage!")


func get_safe_area_percentage() -> float:
	var total_tiles := Config.map_size.x * Config.map_size.y
	var toxic_count := toxic_tiles.size()
	return 100.0 * (1.0 - float(toxic_count) / float(total_tiles))


func mini(a: int, b: int) -> int:
	return a if a < b else b
