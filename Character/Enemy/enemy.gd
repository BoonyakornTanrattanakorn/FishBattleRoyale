extends Character
class_name Enemy

const DIRECTIONS = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN
]

@onready var bomb_placement_system: Node = $BombPlacementSystem

var think_time := 0.5
var menu_mode := false  # Disable bomb placement in menus
var bomb_avoidance_distance := 3.0  # tiles to avoid bombs


func _ready() -> void:
	super()
	set_max_hp(Config.enemy_hp)
	set_hp(Config.enemy_hp)
	
	# Adjust AI based on difficulty
	match Config.difficulty:
		"Easy":
			think_time = 0.7
			bomb_avoidance_distance = 2.0
		"Normal":
			think_time = 0.5
			bomb_avoidance_distance = 3.0
		"Hard":
			think_time = 0.3
			bomb_avoidance_distance = 4.0
	
	ai_loop()


func ai_loop():
	while true:
		if !moving:
			think()
		await get_tree().create_timer(think_time).timeout


func think():
	# Check for nearby bombs and prioritize avoiding them
	var danger_dir := get_danger_direction()
	if danger_dir != Vector2.ZERO:
		move_away_from_danger(danger_dir)
		return
	
	var target: Character = get_closest_player()

	if target:
		chase(target)
		
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
		# Wander intelligently - prefer unexplored directions
		smart_wander()


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
	
	return true


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
	queue_free()
