extends Character
class_name Enemy

signal enemy_died(enemy_name: String)

const DIRECTIONS = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN
]

@onready var bomb_placement_system: Node = $BombPlacementSystem
@onready var power_up_system: Node = $PowerUpSystem

var think_time := 1.0
var menu_mode := false  # Disable bomb placement in menus
var bomb_avoidance_distance := 2.0  # tiles to avoid bombs
var panic_mode := false  # True when in toxic zone and need to escape
var search_depth := 8  # How far to look ahead when pathfinding


func _ready() -> void:
	super()
	add_to_group("enemies")  # For toxic zone damage and tracking
	set_max_hp(Config.enemy_hp)
	set_hp(Config.enemy_hp)
	
	# Adjust AI based on difficulty
	match Config.difficulty:
		"Easy":
			think_time = 1.0
			bomb_avoidance_distance = 2.0
		"Normal":
			think_time = 0.7
			bomb_avoidance_distance = 3.0
		"Hard":
			think_time = 0.5
			bomb_avoidance_distance = 4.0
	
	ai_loop()


func ai_loop():
	while true:
		if !moving:
			think()
		await get_tree().create_timer(think_time).timeout


func think():
	# Priority 1: Escape if currently in toxic zone
	if is_position_toxic(position):
		panic_mode = true
		escape_toxic_zone()
		return
	
	panic_mode = false
	
	# Priority 2: Check for nearby bombs and prioritize avoiding them
	var danger_dir := get_danger_direction()
	if danger_dir != Vector2.ZERO:
		move_away_from_danger(danger_dir)
		return
	
	# Priority 3: Chase player but prefer safe paths
	var target: Character = get_closest_player()

	if target:
		chase_with_safety(target)
		
		# Smart bomb placement: place bomb when close to player
		var distance := position.distance_to(target.position)
		var bomb_chance := 0.4  # Base chance
		
		# Adjust based on difficulty
		match Config.difficulty:
			"Easy":
				bomb_chance = 0.3
			"Normal":
				bomb_chance = 0.5
			"Hard":
				bomb_chance = 0.7
		
		if not menu_mode and distance < Config.tile_size * 3 and randf() < bomb_chance:
			bomb_placement_system.place_bomb()
	else:
		# Priority 4: Move toward center when wandering (avoid edges/toxic zones)
		move_toward_center()


func chase(target: Character):
	var delta: Vector2 = target.position - position

	# Primary direction based on distance
	var primary_dir: Vector2
	var secondary_dir: Vector2
	
	if abs(delta.x) > abs(delta.y):
		primary_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
		secondary_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
	else:
		primary_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
		secondary_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT

	# Try primary direction first, then secondary, then perpendicular
	if can_move_in_direction(primary_dir):
		move(primary_dir)
	elif can_move_in_direction(secondary_dir):
		move(secondary_dir)
	else:
		# Try any valid direction
		for dir in DIRECTIONS:
			if can_move_in_direction(dir):
				move(dir)
				return


func chase_with_safety(target: Character):
	# Enhanced chase that considers toxic zones
	var delta: Vector2 = target.position - position

	# Primary direction based on distance
	var primary_dir: Vector2
	var secondary_dir: Vector2
	
	if abs(delta.x) > abs(delta.y):
		primary_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
		secondary_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
	else:
		primary_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
		secondary_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT

	# Try primary direction first (if safe), then secondary, then any safe direction
	if can_move_in_direction(primary_dir):
		move(primary_dir)
	elif can_move_in_direction(secondary_dir):
		move(secondary_dir)
	else:
		# Try any valid direction, preferring non-toxic
		var safe_directions = []
		var risky_directions = []
		
		for dir in DIRECTIONS:
			var target_pos = position + (dir * Config.tile_size)
			if can_move_in_direction_ignore_toxic(dir):
				if not is_position_toxic(target_pos):
					safe_directions.append(dir)
				else:
					risky_directions.append(dir)
		
		# Prefer safe directions
		if safe_directions.size() > 0:
			move(safe_directions[0])
		elif risky_directions.size() > 0:
			move(risky_directions[0])


func escape_toxic_zone():
	# Use BFS pathfinding to find nearest safe tile
	var safe_dir = find_best_safe_direction()
	
	if safe_dir != Vector2.ZERO:
		move(safe_dir)
	else:
		# No clear path found, try any direction that moves away from toxic
		var best_dir := Vector2.ZERO
		var best_toxic_count := INF
		
		for dir in DIRECTIONS:
			if can_move_in_direction_ignore_toxic(dir):
				var test_pos = position + (dir * Config.tile_size)
				# Count toxic neighbors at test position
				var toxic_neighbors = count_toxic_neighbors(test_pos)
				if toxic_neighbors < best_toxic_count:
					best_toxic_count = toxic_neighbors
					best_dir = dir
		
		if best_dir != Vector2.ZERO:
			move(best_dir)


func move_toward_center():
	# Move toward the center of the map to avoid edges
	var center_pos = get_center_position()
	var delta = center_pos - position
	
	# If already near center, just wander
	if delta.length() < Config.tile_size * 2:
		smart_wander()
		return
	
	# Try to move toward center
	var primary_dir: Vector2
	var secondary_dir: Vector2
	
	if abs(delta.x) > abs(delta.y):
		primary_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
		secondary_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
	else:
		primary_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
		secondary_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
	
	# Try directions toward center
	if can_move_in_direction(primary_dir):
		move(primary_dir)
	elif can_move_in_direction(secondary_dir):
		move(secondary_dir)
	else:
		smart_wander()


func find_best_safe_direction() -> Vector2:
	# BFS pathfinding to find shortest path to safe tile
	var queue = []
	var visited = {}
	var parent_map = {}
	
	# Start position (grid coordinates)
	var start_grid = Vector2i(position / Config.tile_size)
	queue.append(start_grid)
	visited[start_grid] = true
	parent_map[start_grid] = null
	
	# BFS to find nearest safe tile
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_world = Vector2(current) * Config.tile_size
		
		# Found a safe tile!
		if not is_position_toxic(current_world):
			# Trace back path to find first move direction
			var path_node = current
			while parent_map[path_node] != null:
				var parent = parent_map[path_node]
				if parent == start_grid:
					# This is the first step in our path
					var direction = path_node - start_grid
					return Vector2(direction.x, direction.y)
				path_node = parent
			
			# If we get here, we're already at the target (shouldn't happen)
			return Vector2.ZERO
		
		# Explore neighbors (up, down, left, right)
		for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor = current + dir
			
			if visited.has(neighbor):
				continue
			
			# Check if position is valid and not blocked by walls
			var neighbor_world = Vector2(neighbor) * Config.tile_size
			if not is_position_in_bounds(neighbor_world):
				continue
			
			# Check if we can move there (ignoring toxic for pathfinding)
			var dir_vec2 = Vector2(dir.x, dir.y)
			if can_move_in_direction_ignore_toxic(dir_vec2):
				queue.append(neighbor)
				visited[neighbor] = true
				parent_map[neighbor] = current
		
		# Limit search depth to avoid performance issues
		if visited.size() > search_depth * search_depth:
			break
	
	# No safe path found
	return Vector2.ZERO


func get_center_position() -> Vector2:
	return Vector2(Config.map_size) * Config.tile_size * 0.5


func count_toxic_neighbors(world_pos: Vector2) -> int:
	var count = 0
	for dir in DIRECTIONS:
		var test_pos = world_pos + (dir * Config.tile_size)
		if is_position_toxic(test_pos):
			count += 1
	return count


func is_position_in_bounds(world_pos: Vector2) -> bool:
	var grid_pos = Vector2i(world_pos / Config.tile_size)
	return grid_pos.x >= 0 and grid_pos.x < Config.map_size.x and \
		   grid_pos.y >= 0 and grid_pos.y < Config.map_size.y


func can_move_in_direction_ignore_toxic(dir: Vector2) -> bool:
	# Same as can_move_in_direction but ignores toxic zones
	# Used for pathfinding through toxic to reach safety
	ray.target_position = dir * Config.tile_size
	ray.force_raycast_update()
	if ray.is_colliding():
		return false
	
	# Check if another character is already at the destination
	var target_pos = position + (dir * Config.tile_size)
	var characters := get_tree().get_nodes_in_group("players") + get_tree().get_nodes_in_group("enemies")
	
	for character in characters:
		if character == self or not is_instance_valid(character):
			continue
		# Check if character is at target position (within tolerance)
		if character.position.distance_to(target_pos) < Config.tile_size * 0.5:
			return false
	
	return true


func smart_wander():
	# Try to move in a direction that's not blocked
	var valid_directions = []
	for dir in DIRECTIONS:
		if can_move_in_direction(dir):
			valid_directions.append(dir)
	
	if valid_directions.size() > 0:
		move(valid_directions.pick_random())


func can_move_in_direction(dir: Vector2) -> bool:
	# Check for walls and blocks
	ray.target_position = dir * Config.tile_size
	ray.force_raycast_update()
	if ray.is_colliding():
		return false
	
	# Check if another character is already at the destination
	var target_pos = position + (dir * Config.tile_size)
	var characters := get_tree().get_nodes_in_group("players") + get_tree().get_nodes_in_group("enemies")
	
	for character in characters:
		if character == self or not is_instance_valid(character):
			continue
		# Check if character is at target position (within tolerance)
		if character.position.distance_to(target_pos) < Config.tile_size * 0.5:
			return false
	
	# Avoid toxic zones if possible
	if is_position_toxic(target_pos):
		return false
	
	return true


func is_position_toxic(pos: Vector2) -> bool:
	# Check with toxic zone system if it exists
	var toxic_zone = get_tree().get_first_node_in_group("toxic_zone")
	if toxic_zone and toxic_zone.has_method("is_position_toxic"):
		return toxic_zone.is_position_toxic(pos)
	return false


func get_danger_direction() -> Vector2:
	# Check for nearby bombs
	var bombs := get_tree().get_nodes_in_group("bombs")
	var danger_vector := Vector2.ZERO
	
	for bomb in bombs:
		if not bomb is Bomb:
			continue
			
		var distance := position.distance_to(bomb.position)
		# Danger radius is the bomb's explosion size plus safety margin
		var danger_radius = (bomb.explosion_size + bomb_avoidance_distance) * Config.tile_size
		
		if distance < danger_radius:
			# Add weighted danger vector (closer = more dangerous)
			var dir_from_bomb = (position - bomb.position).normalized()
			var weight = 1.0 - (distance / danger_radius)
			danger_vector += dir_from_bomb * weight
	
	return danger_vector.normalized() if danger_vector.length() > 0.1 else Vector2.ZERO


func move_away_from_danger(danger_dir: Vector2):
	# Convert continuous danger direction to discrete movement
	var best_dir := Vector2.ZERO
	var best_score := -INF
	
	for dir in DIRECTIONS:
		if can_move_in_direction(dir):
			# Score based on alignment with danger escape direction
			var score = dir.dot(danger_dir)
			if score > best_score:
				best_score = score
				best_dir = dir
	
	if best_dir != Vector2.ZERO:
		move(best_dir)
	else:
		# If can't escape, try any direction
		for dir in DIRECTIONS:
			if can_move_in_direction(dir):
				move(dir)
				return



func get_closest_player() -> Character:
	var players := get_tree().get_nodes_in_group("players")
	var closest: Character = null
	var best := INF

	for p in players:
		if p == self:
			continue

		var d := position.distance_squared_to(p.position)
		if d < best:
			best = d
			closest = p

	return closest


func die():
	if is_dead:
		return
	is_dead = true
	GameStats.add_kill()
	
	# In multiplayer, emit signal for server to sync death
	if NetworkManager.is_multiplayer():
		enemy_died.emit(name)
	else:
		# Single player: just remove immediately
		queue_free()


func _on_area_entered(area: Area2D):
	if area is PowerUp:
		power_up_system.enable_power_up(area.type)
		area.queue_free()
