extends Node

# Game statistics
var powerups_collected := 0
var kills := 0
var time_survived := 0.0
var game_active := false
var player_died := false  # Track if player died in current session
var was_multiplayer := false  # Track if current session was multiplayer

var timer: Timer

func _ready() -> void:
	# Create timer for tracking survival time
	timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func start_game() -> void:
	# Reset stats
	powerups_collected = 0
	kills = 0
	time_survived = 0.0
	game_active = true
	timer.start()

func reset_death_state() -> void:
	# Reset death state when starting fresh from menu
	player_died = false

func set_multiplayer_session(is_multiplayer: bool) -> void:
	# Track if this is a multiplayer session
	was_multiplayer = is_multiplayer

func reset_session_state() -> void:
	# Reset all session flags when returning to main menu
	player_died = false
	was_multiplayer = false

func stop_game() -> void:
	game_active = false
	timer.stop()

func mark_player_death() -> void:
	player_died = true

func _on_timer_timeout() -> void:
	if game_active:
		time_survived += 0.1

func add_powerup() -> void:
	powerups_collected += 1

func add_kill() -> void:
	kills += 1

func get_time_formatted() -> String:
	var minutes := int(time_survived) / 60
	var seconds := int(time_survived) % 60
	return "%02d:%02d" % [minutes, seconds]
