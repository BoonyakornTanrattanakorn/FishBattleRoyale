extends Area2D

class_name DirectionalExplosion

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var damaged_characters = []  # Track which characters have been damaged

func play_animation(animation_name: String):
	animated_sprite_2d.play(animation_name)


func _on_area_entered(body: Node2D) -> void:
	if body is Character:
		# Check if character is actually within this tile's bounds
		var distance := global_position.distance_to(body.global_position)
		
		# Only damage if character is within the same tile (with small tolerance)
		if distance < Config.tile_size * 0.7 and body not in damaged_characters:
			damaged_characters.append(body)
			
			# Only server deals damage in multiplayer
			if NetworkManager.is_multiplayer():
				if multiplayer.is_server():
					(body as Character).reduce_hp()
					print("[Server] Bomb hit ", body.name, ", HP = ", body.get_hp())
				# Clients do nothing - they'll receive HP sync from server
			else:
				# Single player
				(body as Character).reduce_hp()
				print("Bomb hit, HP = ", body.get_hp())
