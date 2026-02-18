extends Control

@onready var host_button: Button = $Panel/VBoxContainer/HostButton
@onready var join_button: Button = $Panel/VBoxContainer/JoinButton
@onready var back_button: Button = $Panel/VBoxContainer/BackButton
@onready var player_name_input: LineEdit = $Panel/VBoxContainer/PlayerNameInput
@onready var ip_address_input: LineEdit = $Panel/VBoxContainer/IPAddressInput
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var multiplayer_manager = MultiplayerManager

func _ready() -> void:
	# Set default values
	player_name_input.text = "Player" + str(randi() % 1000)
	ip_address_input.text = "127.0.0.1"
	status_label.text = ""
	
	# Hide IP input initially
	ip_address_input.visible = false
	
	# Connect signals
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect multiplayer manager signals
	multiplayer_manager.player_connected.connect(_on_player_connected)
	multiplayer_manager.server_disconnected.connect(_on_server_disconnected)


func _on_host_pressed() -> void:
	var player_name = player_name_input.text
	if player_name.is_empty():
		status_label.text = "Please enter a player name"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "Creating server..."
	status_label.modulate = Color.YELLOW
	
	var success = multiplayer_manager.create_server(player_name)
	
	if success:
		status_label.text = "Server created! Waiting for players..."
		status_label.modulate = Color.GREEN
		
		# Get local IP for display
		var local_ip = IP.get_local_addresses()
		var display_ip = "127.0.0.1"
		for ip in local_ip:
			if ip.begins_with("192.168.") or ip.begins_with("10."):
				display_ip = ip
				break
		
		status_label.text += "\nShare this IP: " + display_ip
		
		# Wait a moment then go to lobby
		await get_tree().create_timer(1.5).timeout
		go_to_lobby()
	else:
		status_label.text = "Failed to create server"
		status_label.modulate = Color.RED


func _on_join_pressed() -> void:
	# Show IP input if not visible
	if not ip_address_input.visible:
		ip_address_input.visible = true
		join_button.text = "Connect"
		status_label.text = "Enter server IP address"
		status_label.modulate = Color.WHITE
		return
	
	var player_name = player_name_input.text
	var ip_address = ip_address_input.text
	
	if player_name.is_empty():
		status_label.text = "Please enter a player name"
		status_label.modulate = Color.RED
		return
	
	if ip_address.is_empty():
		status_label.text = "Please enter server IP"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "Connecting to " + ip_address + "..."
	status_label.modulate = Color.YELLOW
	
	var success = multiplayer_manager.join_server(ip_address, player_name)
	
	if success:
		# Wait for connection result
		await get_tree().create_timer(3.0).timeout
		
		if multiplayer_manager.is_multiplayer_active():
			status_label.text = "Connected! Joining lobby..."
			status_label.modulate = Color.GREEN
			await get_tree().create_timer(1.0).timeout
			go_to_lobby()
		else:
			status_label.text = "Connection failed or timed out"
			status_label.modulate = Color.RED
			ip_address_input.visible = false
			join_button.text = "Join Game"
	else:
		status_label.text = "Failed to connect"
		status_label.modulate = Color.RED


func _on_back_pressed() -> void:
	multiplayer_manager.disconnect_from_game()
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")


func _on_player_connected(peer_id, player_info):
	print("Player joined: ", player_info["name"])
	status_label.text = "Player joined: " + player_info["name"] + "\nTotal players: " + str(multiplayer_manager.get_player_count())


func _on_server_disconnected():
	status_label.text = "Server disconnected!"
	status_label.modulate = Color.RED


func go_to_lobby():
	get_tree().change_scene_to_file("res://UI/multiplayer_lobby.tscn")
