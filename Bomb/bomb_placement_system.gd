extends Node

class_name BombPlacementSystem

const BOMB_SCENE = preload("res://Bomb/bomb.tscn")

var character: Character = null
var bomb_placed = 0
var explosion_size = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character = get_parent()


func place_bomb():
	if bomb_placed >= character.max_bombs:
		return
	
	var bomb_position = character.position
	
	# In multiplayer, request bomb placement from server
	if NetworkManager.is_multiplayer():
		if multiplayer.is_server():
			# Server can place directly
			_server_spawn_bomb(bomb_position, explosion_size)
		else:
			# Client requests from server
			_request_bomb_placement.rpc_id(1, bomb_position, explosion_size)
	else:
		_spawn_bomb_local(bomb_position, explosion_size)


# Client requests bomb placement from server
@rpc("any_peer", "call_remote", "reliable")
func _request_bomb_placement(bomb_position: Vector2, bomb_explosion_size: int):
	if not multiplayer.is_server():
		return
	
	# Server validates and spawns
	_server_spawn_bomb(bomb_position, bomb_explosion_size)


# Server handles bomb spawning
func _server_spawn_bomb(bomb_position: Vector2, bomb_explosion_size: int):
	if not NetworkManager.is_multiplayer() or multiplayer.is_server():
		# Server spawns locally and tells all clients
		_spawn_bomb_local(bomb_position, bomb_explosion_size)
		
		if NetworkManager.is_multiplayer():
			# Tell all clients to spawn the bomb
			_spawn_bomb_on_clients.rpc(bomb_position, bomb_explosion_size)


# Server tells clients to spawn bomb
@rpc("authority", "call_remote", "reliable")
func _spawn_bomb_on_clients(bomb_position: Vector2, bomb_explosion_size: int):
	_spawn_bomb_local(bomb_position, bomb_explosion_size)


# Local bomb spawning logic
func _spawn_bomb_local(bomb_position: Vector2, bomb_explosion_size: int):
	var bomb = BOMB_SCENE.instantiate()
	bomb.explosion_size = bomb_explosion_size
	bomb.position = bomb_position
	get_tree().root.add_child(bomb)
	bomb_placed += 1
	
	bomb.tree_exiting.connect(on_bomb_exploded)


func on_bomb_exploded():
	bomb_placed -= 1
