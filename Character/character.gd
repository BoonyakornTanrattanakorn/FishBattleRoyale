extends Area2D
class_name Character

@onready var ray: RayCast2D = $RayCast2D

var animation_speed := 3.0
var moving := false

var hp := 3
var max_hp := 3

var invincible := false
var invincible_time := 1.0
var is_dead := false

var max_bombs := 1


func _ready():
	position = position.snapped(Vector2.ONE * Config.tile_size)
	position += Vector2.ONE * Config.tile_size / 2


func move(dir: Vector2) -> void:
	if moving:
		return

	ray.target_position = dir * Config.tile_size
	ray.force_raycast_update()

	if ray.is_colliding():
		return
	
	# Check if there's another character at the target position
	var target_pos = position + dir * Config.tile_size
	var overlapping_characters := get_tree().get_nodes_in_group("player")
	overlapping_characters.append_array(get_tree().get_nodes_in_group("enemies"))
	
	for character in overlapping_characters:
		if character is Character and character != self:
			# Check if the character is at the target position (within tile boundaries)
			var distance = character.position.distance_to(target_pos)
			if distance < Config.tile_size * 0.5:  # Within half a tile
				return  # Blocked by another character

	# Cancel invincibility when moving
	invincible = false
	
	# In multiplayer, sync enemy movement from server to clients
	if self is Enemy and NetworkManager.is_multiplayer() and multiplayer.is_server():
		_sync_enemy_move.rpc(dir)

	var tween := create_tween()
	tween.tween_property(
		self,
		"position",
		position + dir * Config.tile_size,
		1.0 / animation_speed
	)

	moving = true
	await tween.finished
	moving = false


# RPC to sync enemy movement to clients
@rpc("authority", "call_remote", "reliable")
func _sync_enemy_move(dir: Vector2) -> void:
	# Client receives move command and executes it
	if moving:
		return
	
	var tween := create_tween()
	tween.tween_property(
		self,
		"position",
		position + dir * Config.tile_size,
		1.0 / animation_speed
	)
	
	moving = true
	await tween.finished
	moving = false


# ---------------- HP SYSTEM ----------------

func reduce_hp():
	if invincible or is_dead:
		return

	set_hp(hp - 1)
	
	# Sync HP to clients in multiplayer
	if NetworkManager.is_multiplayer() and multiplayer.is_server():
		_sync_hp.rpc(hp)

	if hp <= 0:
		die()
	else:
		start_invincible()


# RPC to sync HP from server to clients
@rpc("authority", "call_remote", "reliable")
func _sync_hp(new_hp: int):
	hp = new_hp
	# Trigger any visual updates (override in subclasses if needed)


func start_invincible():
	invincible = true
	if is_dead:
		return
	await get_tree().create_timer(invincible_time).timeout
	invincible = false


func die():
	if is_dead:
		return
	is_dead = true
	queue_free()


func set_hp(value: int):
	hp = clamp(value, 0, max_hp)


func get_hp() -> int:
	return hp


func set_max_hp(value: int):
	max_hp = value
