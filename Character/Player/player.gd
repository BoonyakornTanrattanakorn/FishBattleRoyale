extends Character
class_name Player

signal healthChanged
signal player_died(player_id: int)

# Player identification and input configuration
@export var player_id: int = 1
@export var input_up: String = "Up"
@export var input_down: String = "Down"
@export var input_left: String = "Left"
@export var input_right: String = "Right"
@export var input_bomb: String = "PlaceBomb"
@export var use_builtin_ui: bool = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var bomb_placement_system: BombPlacementSystem = $BombPlacementSystem
@onready var power_up_system: Node = $PowerUpSystem

@onready var heart_container: HBoxContainer = $CanvasLayer/heartContainer
@onready var powerup_display: HBoxContainer = $CanvasLayer/PowerupDisplay
@onready var camera: Camera2D = $Camera2D
@onready var name_label: Label = $NameLabel

var peer_id: int = 1  # Multiplayer peer ID
var player_name: String = "Player"

func _ready() -> void:
	super()
	add_to_group("players")  # For toxic zone detection
	set_max_hp(Config.player_hp)
	set_hp(Config.player_hp)
	
	if use_builtin_ui:
		heart_container.setMaxHearts(Config.player_hp)
		heart_container.updateHearts(get_hp())
		healthChanged.connect(heart_container.updateHearts)
		power_up_system.powerups_changed.connect(powerup_display.update_display)
	
func _input(_event):
	# Only process input for the local player
	if not is_multiplayer_authority():
		return
	
	if moving:
		return

	if Input.is_action_pressed(input_right):
		move(Vector2.RIGHT)
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed(input_left):
		move(Vector2.LEFT)
		animated_sprite_2d.flip_h = true
	elif Input.is_action_pressed(input_up):
		move(Vector2.UP)
	elif Input.is_action_pressed(input_down):
		move(Vector2.DOWN)

	if Input.is_action_just_pressed(input_bomb):
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
	print("Player ", player_id, " died")
	
	# Check player count BEFORE emitting signal (signal handler may change scene)
	var all_players = get_tree().get_nodes_in_group("player")
	var is_single_player = all_players.size() <= 1
	
	if is_single_player:
		# Single player mode - end the game immediately
		GameStats.stop_game()
		get_tree().change_scene_to_file("res://UI/game_over.tscn")
	else:
		# Multiplayer mode - emit signal and hide the player
		# Note: signal handler may change scene, so do cleanup first
		visible = false
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		player_died.emit(player_id)


func _on_area_entered(area: Area2D):
	if area is PowerUp:
		GameStats.add_powerup()
		power_up_system.enable_power_up(area.type)
		area.queue_free()


# ============= MULTIPLAYER SYNC =============
@rpc("any_peer", "call_local")
func sync_sprite_flip(flip: bool):
	animated_sprite_2d.flip_h = flip
