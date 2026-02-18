extends Character
class_name Player

signal healthChanged

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var bomb_placement_system: BombPlacementSystem = $BombPlacementSystem
@onready var power_up_system: Node = $PowerUpSystem
@onready var name_label: Label = $NameLabel

@onready var heart_container: HBoxContainer = $CanvasLayer/heartContainer
@onready var powerup_display: HBoxContainer = $CanvasLayer/PowerupDisplay
@onready var camera: Camera2D = $Camera2D

var peer_id: int = 1  # Default to server/single player
var player_name: String = "Player"

func _ready() -> void:
	super()
	add_to_group("player")  # For toxic zone detection
	set_max_hp(Config.player_hp)
	set_hp(Config.player_hp)
	heart_container.setMaxHearts(Config.player_hp)
	heart_container.updateHearts(get_hp())
	healthChanged.connect(heart_container.updateHearts)
	power_up_system.powerups_changed.connect(powerup_display.update_display)
	
	# Set player name and color from NetworkManager
	if NetworkManager.is_multiplayer():
		player_name = NetworkManager.get_player_name(peer_id)
		
		# Different colors for different players
		if peer_id == 1:
			name_label.modulate = Color.YELLOW
		else:
			var colors := [Color.CYAN, Color.GREEN, Color.MAGENTA, Color.ORANGE]
			name_label.modulate = colors[(peer_id - 2) % colors.size()]
	else:
		# Single player mode - get name from NetworkManager if available
		player_name = NetworkManager.get_player_name(peer_id)
		if player_name == "Player 1":
			# Fallback if no name was set
			player_name = "Player"
		name_label.modulate = Color.WHITE
	
	name_label.text = player_name
	print("Player %d name set to: %s" % [peer_id, player_name])
	
	# Set up multiplayer authority
	if NetworkManager.is_multiplayer():
		# Authority should already be set by spawn function, but set it again to be safe
		if get_multiplayer_authority() != peer_id:
			set_multiplayer_authority(peer_id)
		
		print("Player %d authority set. Is authority: %s" % [peer_id, is_multiplayer_authority()])
		print("My unique ID: %d, Peer ID: %d" % [multiplayer.get_unique_id(), peer_id])
		
		# Only enable camera and UI for local player
		if is_multiplayer_authority():
			camera.enabled = true
			heart_container.visible = true
			powerup_display.visible = true
			print("Player %d: Enabled camera and HUD (LOCAL PLAYER)" % peer_id)
		else:
			camera.enabled = false
			heart_container.visible = false
			powerup_display.visible = false
			print("Player %d: Remote player - disabled camera and HUD" % peer_id)
		
		NetworkManager.register_player(peer_id, self)
	else:
		# Single player mode
		camera.enabled = true
		print("Single player mode - camera enabled")
	
func _input(_event):
	# Only process input for local player in multiplayer
	if NetworkManager.is_multiplayer() and not is_multiplayer_authority():
		return
	
	if moving:
		return

	if Input.is_action_pressed("Right"):
		move(Vector2.RIGHT)
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed("Left"):
		move(Vector2.LEFT)
		animated_sprite_2d.flip_h = true
	elif Input.is_action_pressed("Up"):
		move(Vector2.UP)
	elif Input.is_action_pressed("Down"):
		move(Vector2.DOWN)

	if Input.is_action_just_pressed("PlaceBomb"):
		bomb_placement_system.place_bomb()

func move(dir):
	ray.target_position = dir * Config.tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		# Cancel invincibility when moving
		if invincible:
			invincible = false
			animated_sprite_2d.modulate.a = 1.0
		
		var tween = create_tween()
		tween.tween_property(self, "position",
			position + dir * Config.tile_size, 1.0/animation_speed).set_trans(Tween.TRANS_SINE)
		moving = true
		await tween.finished
		moving = false
		
func reduce_hp():
	set_hp(get_hp()-1)
	healthChanged.emit(hp)
	if get_hp() <= 0:
		die()

# Override invincible for blinking
func start_invincible():
	invincible = true

	var tween := create_tween()
	tween.set_loops(int(invincible_time / 0.1))
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.3, 0.05)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.05)

	await get_tree().create_timer(invincible_time).timeout

	invincible = false
	animated_sprite_2d.modulate.a = 1.0


func die():
	if is_dead:
		return
	is_dead = true
	print("player died")
	
	# In multiplayer, enable spectator mode instead of game over
	if NetworkManager.is_multiplayer():
		if is_multiplayer_authority():
			GameStats.mark_player_death()
			GameStats.stop_game()
			# Enter spectator mode
			_enter_spectator_mode()
		else:
			# Other player died - hide them completely from alive players
			visible = false
			# Disable collision completely
			var collision_shape = get_node_or_null("CollisionShape2D")
			if collision_shape:
				collision_shape.set_deferred("disabled", true)
	else:
		# Single player - show game over screen
		GameStats.mark_player_death()
		GameStats.stop_game()
		get_tree().change_scene_to_file("res://UI/game_over.tscn")


func _enter_spectator_mode():
	# Make player transparent
	animated_sprite_2d.modulate.a = 0.3
	name_label.text = player_name + " (Spectating)"
	name_label.modulate = Color.GRAY
	
	# Completely disable collision
	collision_layer = 0
	collision_mask = 0
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Disable Area2D monitoring
	monitoring = false
	monitorable = false
	
	# Disable raycast
	if ray:
		ray.enabled = false
	
	# Show spectator UI
	var spectator_ui = load("res://UI/spectator_ui.tscn").instantiate()
	get_tree().root.add_child(spectator_ui)
	
	# Camera and UI stay active so player can watch
	print("Entered spectator mode. Camera remains active.")


func _on_area_entered(area: Area2D):
	if area is PowerUp:
		GameStats.add_powerup()
		power_up_system.enable_power_up(area.type)
		area.queue_free()
