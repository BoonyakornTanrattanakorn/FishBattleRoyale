extends Node

# Game statistics
var powerups_collected := 0
var kills := 0
var time_survived := 0.0
var game_active := false

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

func stop_game() -> void:
	game_active = false
	timer.stop()

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
