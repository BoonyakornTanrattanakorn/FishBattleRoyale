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
	
	# In multiplayer, use RPC to sync bomb placement across all clients
	if NetworkManager.is_multiplayer():
		_spawn_bomb_rpc.rpc(bomb_position, explosion_size)
	else:
		_spawn_bomb_local(bomb_position, explosion_size)


# RPC method to spawn bomb on all clients
@rpc("any_peer", "call_local", "reliable")
func _spawn_bomb_rpc(bomb_position: Vector2, bomb_explosion_size: int):
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
