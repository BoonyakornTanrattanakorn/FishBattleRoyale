extends Node

class_name BombPlacementSystem

const BOMB_SCENE = preload("res://Bomb/bomb.tscn")


#var fish: Fish = null
var player: Player = null
var bomb_placed = 0
var explosion_size = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#fish = get_parent()
	player = get_parent()


func place_bomb():
	if bomb_placed >= player.max_bombs:
		return
		
	var bomb = BOMB_SCENE.instantiate()
	#var fish_position = fish.position
	var player_position = player.position
	var bomb_position = player_position
	
	bomb.explosion_size = explosion_size
	bomb.position = bomb_position
	get_tree().root.add_child(bomb)
	bomb_placed += 1
	
	bomb.tree_exiting.connect(on_bomb_exploded)


func on_bomb_exploded():
	bomb_placed -= 1
