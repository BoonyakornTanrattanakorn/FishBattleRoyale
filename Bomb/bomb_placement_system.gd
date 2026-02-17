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
		
	var bomb = BOMB_SCENE.instantiate()
	var character_position = character.position
	var bomb_position = character_position
	
	bomb.explosion_size = explosion_size
	bomb.position = bomb_position
	get_tree().root.add_child(bomb)
	bomb_placed += 1
	
	bomb.tree_exiting.connect(on_bomb_exploded)


func on_bomb_exploded():
	bomb_placed -= 1
