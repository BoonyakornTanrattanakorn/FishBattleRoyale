extends Area2D

class_name CenterExplosion

@onready var raycasts: Array[RayCast2D] = [
	$Raycasts/RayCastUp,
	$Raycasts/RayCastDown,
	$Raycasts/RayCastLeft,
	$Raycasts/RayCastRight
]

var animation_names = ["up", "down", "left", "right"]
var animation_dirs: Array[Vector2] = [
	Vector2(0, -Config.tile_size),
	Vector2(0, Config.tile_size),
	Vector2(-Config.tile_size, 0),
	Vector2(Config.tile_size, 0)
]

const DIRECTIONAL_EXPLOSION = preload("res://Bomb/directional_explosion.tscn")

# Explosion size for all directions
var size = 1

func _ready() -> void:
	check_reycasts()

func check_reycasts():
	for i in raycasts.size():
		check_raycast_for_direction(animation_names[i], raycasts[i], animation_dirs[i])

func check_raycast_for_direction(animation_name: String, raycast: RayCast2D, animation_dir: Vector2):
	raycast.target_position = raycast.target_position * size
	raycast.force_raycast_update()
	
	if !raycast.is_colliding():
		create_explosion_for_size(size, animation_name, animation_dir)
	else:
		var size_of_explosion = calculate_size_of_explosion(raycast)
		
		var collider = raycast.get_collider()
		if size_of_explosion != null:
			create_explosion_for_size(size_of_explosion, animation_name, animation_dir)
		execute_explosion_collision(collider)

func create_explosion_for_size(_size: int, animation_name: String, animation_pos: Vector2):
	for i in _size:
		if i < _size - 1:
			create_explosion_animation_slice("%s_mid" % animation_name, animation_pos * (i+1))
		else:
			create_explosion_animation_slice("%s_end" % animation_name, animation_pos * (i+1))

func create_explosion_animation_slice(animation_name: String, animation_pos: Vector2):
	var directional_explosion = DIRECTIONAL_EXPLOSION.instantiate()
	directional_explosion.position = animation_pos
	add_child(directional_explosion)
	directional_explosion.play_animation(animation_name)

func calculate_size_of_explosion(raycast: RayCast2D):
	var collider = raycast.get_collider()
	if collider is Block or collider is Wall:
		var collision_point = raycast.get_collision_point()
		
		var distance_to_collider = raycast.global_position.distance_to(collision_point)
		# Calculate how many complete tiles are between bomb and wall
		# Add small epsilon to handle floating point precision, then floor to get complete tiles
		var tiles_distance = floor((distance_to_collider + 0.1) / Config.tile_size)
		var size_of_explosion_before_collider = max(int(tiles_distance), 0)
		return size_of_explosion_before_collider

func execute_explosion_collision(collider: Object):
	if collider as DestructibleBlock:
		(collider as DestructibleBlock).destroy()

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
