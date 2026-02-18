extends DestructibleBlock

class_name Coral

const POWER_UP_SCENE = preload("res://PowerUp/power_up.tscn")

@export var bomb_up_res: PowerUpRes
@export var fire_up_res: PowerUpRes
@export var speed_up_res: PowerUpRes

func destroy():
	# Only server handles destruction in multiplayer
	if NetworkManager.is_multiplayer():
		if multiplayer.is_server():
			_server_destroy()
		# Clients will receive RPC from server
	else:
		# Single player
		_execute_destroy()


# Server handles destruction logic
func _server_destroy():
	var should_spawn_powerup = randf() <= Config.item_drop_chance
	var powerup_type = -1
	
	if should_spawn_powerup:
		var indicator = randf()
		if indicator <= 0.35:
			powerup_type = 0  # bomb_up
		elif indicator <= 0.70:
			powerup_type = 1  # fire_up
		else:
			powerup_type = 2  # speed_up
	
	# Destroy locally
	_execute_destroy()
	
	# Tell all clients to destroy and spawn powerup if needed
	_sync_destroy.rpc(should_spawn_powerup, powerup_type)


# RPC to sync destruction across clients
@rpc("authority", "call_remote", "reliable")
func _sync_destroy(spawn_powerup: bool, powerup_type: int):
	_execute_destroy()
	
	if spawn_powerup:
		var new_power_up = POWER_UP_SCENE.instantiate()
		new_power_up.global_position = global_position
		get_parent().add_child(new_power_up)
		
		match powerup_type:
			0:
				new_power_up.init(bomb_up_res)
			1:
				new_power_up.init(fire_up_res)
			2:
				new_power_up.init(speed_up_res)


func _execute_destroy():
	# Single player destruction
	if not NetworkManager.is_multiplayer():
		if randf() <= Config.item_drop_chance:
			spawn_power_up()
	
	queue_free()

func spawn_power_up():
	var new_power_up = POWER_UP_SCENE.instantiate()
	new_power_up.global_position = global_position
	get_parent().add_child(new_power_up)
	
	var indicator = randf()
	if (indicator <= 0.35):
		new_power_up.init(bomb_up_res)
	elif (indicator <= 0.70):
		new_power_up.init(fire_up_res)
	else:
		new_power_up.init(speed_up_res)
		
