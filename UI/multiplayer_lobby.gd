extends Control

@onready var host_button: Button = $ScrollContainer/MainContainer/HostContainer/HostButton
@onready var join_button: Button = $ScrollContainer/MainContainer/JoinContainer/JoinButton
@onready var start_button: Button = $ScrollContainer/MainContainer/StartButton
@onready var back_button: Button = $ScrollContainer/MainContainer/BackButton

@onready var name_input: LineEdit = $ScrollContainer/MainContainer/PlayerNameContainer/NameInput
@onready var random_name_button: Button = $ScrollContainer/MainContainer/PlayerNameContainer/RandomNameButton

@onready var host_port_input: LineEdit = $ScrollContainer/MainContainer/HostContainer/HBoxContainer/PortInput
@onready var join_address_input: LineEdit = $ScrollContainer/MainContainer/JoinContainer/AddressContainer/AddressInput
@onready var join_port_input: LineEdit = $ScrollContainer/MainContainer/JoinContainer/PortContainer/PortInput

@onready var status_label: Label = $ScrollContainer/MainContainer/StatusLabel
@onready var players_list: RichTextLabel = $ScrollContainer/MainContainer/PlayersList

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var players := {}  # peer_id -> player_name
var my_player_name := ""

func _ready() -> void:
	# Generate initial random name
	my_player_name = FishNames.generate_random_name()
	name_input.text = my_player_name
	
	# Connect buttons
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	random_name_button.pressed.connect(_on_random_name_pressed)
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_random_name_pressed() -> void:
	my_player_name = FishNames.generate_random_name()
	name_input.text = my_player_name


func _on_host_pressed() -> void:
	# Get player name
	my_player_name = name_input.text.strip_edges()
	if my_player_name.is_empty():
		my_player_name = FishNames.generate_random_name()
		name_input.text = my_player_name
	
	var port := int(host_port_input.text)
	if port <= 0:
		port = DEFAULT_PORT
	
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		status_label.text = "Error: Failed to host (Port might be in use)"
		status_label.modulate = Color.RED
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Add self to players with name
	players[1] = my_player_name
	NetworkManager.players_data[1] = {"name": my_player_name}
	
	# Disable host/join buttons
	host_button.disabled = true
	join_button.disabled = true
	
	# Show start button (only host can start)
	start_button.visible = true
	
	status_label.text = "Status: Hosting on port %d" % port
	status_label.modulate = Color.GREEN
	
	update_players_list()
	print("Server started on port ", port)


func _on_join_pressed() -> void:
	# Get player name
	my_player_name = name_input.text.strip_edges()
	if my_player_name.is_empty():
		my_player_name = FishNames.generate_random_name()
		name_input.text = my_player_name
	
	var address := join_address_input.text
	var port := int(join_port_input.text)
	
	if address.is_empty():
		address = "127.0.0.1"
	if port <= 0:
		port = DEFAULT_PORT
	
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	
	if error != OK:
		status_label.text = "Error: Failed to connect"
		status_label.modulate = Color.RED
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Disable host/join buttons
	host_button.disabled = true
	join_button.disabled = true
	
	status_label.text = "Status: Connecting to %s:%d..." % [address, port]
	status_label.modulate = Color.YELLOW
	
	print("Connecting to ", address, ":", port)


func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	# Request player info from new peer
	if multiplayer.is_server():
		# Server: wait for player to send their name
		# Sync all current players to the new peer
		_sync_players.rpc_id(id, players)
	update_players_list()


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	var player_name = players.get(id, "")
	if player_name:
		FishNames.release_name(player_name)
	players.erase(id)
	NetworkManager.players_data.erase(id)
	update_players_list()


func _on_connected_to_server() -> void:
	print("Successfully connected to server")
	var my_id := multiplayer.get_unique_id()
	players[my_id] = my_player_name
	NetworkManager.players_data[my_id] = {"name": my_player_name}
	
	# Send our name to server
	_register_player_name.rpc_id(1, my_id, my_player_name)
	
	status_label.text = "Status: Connected! Waiting for game start..."
	status_label.modulate = Color.GREEN
	
	update_players_list()


func _on_connection_failed() -> void:
	print("Connection failed")
	status_label.text = "Status: Connection failed!"
	status_label.modulate = Color.RED
	
	# Re-enable buttons
	host_button.disabled = false
	join_button.disabled = false
	
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	print("Server disconnected")
	status_label.text = "Status: Server disconnected"
	status_label.modulate = Color.RED
	
	multiplayer.multiplayer_peer = null
	players.clear()
	update_players_list()
	
	# Re-enable buttons
	host_button.disabled = false
	join_button.disabled = false
	start_button.visible = false


@rpc("any_peer", "reliable")
func _sync_players(all_players: Dictionary) -> void:
	players = all_players
	update_players_list()


@rpc("any_peer", "reliable")
func _add_player(id: int, player_name: String) -> void:
	players[id] = player_name
	update_players_list()


@rpc("any_peer", "reliable")
func _register_player_name(peer_id: int, player_name: String) -> void:
	if multiplayer.is_server():
		# Check if name is taken, if so generate a new one
		var final_name := player_name
		var attempt := 1
		while final_name in players.values():
			final_name = "%s_%d" % [player_name, attempt]
			attempt += 1
		
		players[peer_id] = final_name
		NetworkManager.players_data[peer_id] = {"name": final_name}
		
		# Notify all clients about the new player
		_add_player.rpc(peer_id, final_name)
		
		# If name was changed, notify the client
		if final_name != player_name:
			_update_your_name.rpc_id(peer_id, final_name)


@rpc("authority", "reliable")
func _update_your_name(new_name: String) -> void:
	my_player_name = new_name
	name_input.text = new_name
	var my_id := multiplayer.get_unique_id()
	players[my_id] = new_name
	NetworkManager.players_data[my_id] = {"name": new_name}
	update_players_list()
	status_label.text = "Status: Name changed to '%s' (original was taken)" % new_name


func update_players_list() -> void:
	var text := "[center][b]Players: %d / %d[/b]\n\n" % [players.size(), MAX_PLAYERS]
	
	for id in players:
		var player_name = players[id]
		if id == 1:
			text += "[color=yellow]★ %s (Host)[/color]\n" % player_name
		elif id == multiplayer.get_unique_id():
			text += "[color=cyan]● %s (You)[/color]\n" % player_name
		else:
			text += "● %s\n" % player_name
	
	text += "[/center]"
	players_list.text = text


func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	
	if players.size() < 1:
		status_label.text = "Need at least 1 player to start!"
		status_label.modulate = Color.RED
		return
	
	# Notify all clients to start game
	_start_game.rpc()


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	# Reset death state when starting multiplayer game
	GameStats.reset_death_state()
	get_tree().change_scene_to_file("res://Map/TestMap/test_map.tscn")


func _on_back_pressed() -> void:
	# Disconnect if connected
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Clear used names
	FishNames.clear_all_names()
	
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
