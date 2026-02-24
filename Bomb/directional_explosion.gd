extends Area2D

class_name DirectionalExplosion

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var damaged_characters = []  # Track which characters have been damaged

func play_animation(animation_name: String):
	animated_sprite_2d.play(animation_name)

func _on_area_entered(area: Area2D) -> void:
	if area is Character:
		# Check if character is actually within this tile's bounds
		var distance := global_position.distance_to(area.global_position)
		
		# Only damage if character is within the same tile (with small tolerance)
		if distance < Config.tile_size * 0.7 and area not in damaged_characters:
			damaged_characters.append(area)
			(area as Character).reduce_hp()
			print("Bomb hit, HP = ", area.get_hp())
			
	if area is Bomb:
		# Check if bomb is actually within this tile's bounds
		var distance := global_position.distance_to(area.global_position)
		
		# Only trigger if bomb is within the same tile (with small tolerance)
		if distance < Config.tile_size * 0.7:
			(area as Bomb).explode()
