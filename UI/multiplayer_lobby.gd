extends Control

@onready var player_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/PlayerList
@onready var start_button: Button = $Panel/VBoxContainer/StartButton
@onready var back_button: Button = $Panel/VBoxContainer/BackButton
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var lobby_title: Label = $Panel/VBoxContainer/Title

var is_host: bool = false

func _ready() -> void:
	# Determine if we're the host
	is_host = MultiplayerManager.is_server()
	
	# Update UI based on role
	if is_host:
		lobby_title.text = "Lobby (Host)"
		start_button.visible = true
		start_button.disabled = false
		status_label.text = "Waiting for players... (1/" + str(MultiplayerManager.MAX_PLAYERS) + ")\nYou can start when ready!"
	else:
		lobby_title.text = "Lobby (Client)"
		start_button.visible = false
		status_label.text = "Waiting for host to start the game..."
	
	# Connect signals
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect multiplayer signals
	MultiplayerManager.player_connected.connect(_on_player_connected)
	MultiplayerManager.player_disconnected.connect(_on_player_disconnected)
	MultiplayerManager.server_disconnected.connect(_on_server_disconnected)
	
	# Populate initial player list
	refresh_player_list()


func refresh_player_list():
	# Clear existing list
	for child in player_list.get_children():
		child.queue_free()
	
	# Add all connected players
	for peer_id in MultiplayerManager.players.keys():
		var player_info = MultiplayerManager.players[peer_id]
		add_player_to_list(peer_id, player_info["name"])


func add_player_to_list(peer_id: int, player_name: String):
	var player_label = Label.new()
	var role_text = " (Host)" if peer_id == 1 else ""
	var you_text = " (You)" if peer_id == MultiplayerManager.get_local_peer_id() else ""
	
	player_label.text = "🐟 " + player_name + role_text + you_text
	player_label.add_theme_font_size_override("font_size", 18)
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_label.name = "Player_" + str(peer_id)
	
	player_list.add_child(player_label)


func _on_player_connected(peer_id, player_info):
	print("Player joined lobby: ", player_info["name"])
	refresh_player_list()
	
	var player_count = MultiplayerManager.get_player_count()
	if is_host:
		status_label.text = str(player_count) + "/" + str(MultiplayerManager.MAX_PLAYERS) + " players connected.\nClick Start when ready!"
	else:
		status_label.text = str(player_count) + "/" + str(MultiplayerManager.MAX_PLAYERS) + " players connected.\nWaiting for host..."


func _on_player_disconnected(peer_id):
	print("Player left lobby: ", peer_id)
	refresh_player_list()
	
	var player_count = MultiplayerManager.get_player_count()
	if is_host:
		status_label.text = str(player_count) + "/" + str(MultiplayerManager.MAX_PLAYERS) + " players connected.\nClick Start when ready!"


func _on_server_disconnected():
	status_label.text = "Host disconnected!"
	status_label.modulate = Color.RED
	await get_tree().create_timer(2.0).timeout
	_on_back_pressed()


func _on_start_pressed() -> void:
	if not is_host:
		return
	
	status_label.text = "Starting game..."
	status_label.modulate = Color.GREEN
	
	# Mark game as started
	MultiplayerManager.start_multiplayer_game()
	
	# Notify all clients to start the game
	start_game.rpc()
	
	# Start the game locally
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Map/TestMap/test_map.tscn")


@rpc("authority", "call_local", "reliable")
func start_game():
	# Called on all clients when host starts the game
	print("Game starting!")
	if not is_host:
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Map/TestMap/test_map.tscn")


func _on_back_pressed() -> void:
	# Disconnect from multiplayer session
	MultiplayerManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
