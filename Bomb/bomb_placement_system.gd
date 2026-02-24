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
	
	var bomb_position = character.global_position
	
	# Check if there's already a bomb at this position
	var space_state = character.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = bomb_position
	query.collision_mask = 8  # Bomb collision layer
	query.collide_with_areas = true
	var results = space_state.intersect_point(query)
	
	for result in results:
		if result.collider is Bomb:
			return  # Already a bomb here, don't place another
	
	var bomb = BOMB_SCENE.instantiate()
	bomb.explosion_size = explosion_size
	bomb.global_position = bomb_position
	
	# Add bomb to the same parent as the character (game world)
	character.get_parent().add_child(bomb)
	bomb_placed += 1
	
	bomb.tree_exiting.connect(on_bomb_exploded)


@rpc("any_peer", "call_local")
func create_bomb_rpc(pos: Vector2, size: int):
	# Only execute on remote clients (not the sender)
	if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id():
		var bomb = BOMB_SCENE.instantiate()
		bomb.explosion_size = size
		bomb.position = pos
		get_tree().root.add_child(bomb)


func on_bomb_exploded():
	bomb_placed -= 1
