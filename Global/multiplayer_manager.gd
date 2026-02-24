extends Node

# Multiplayer Manager - Handles all networking for local WiFi multiplayer
# Uses Godot's high-level multiplayer API with ENet

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal game_started

const PORT = 7777
const MAX_PLAYERS = 4
const SERVER_IP = "127.0.0.1"  # Default localhost, can be changed to LAN IP

var players = {}  # Dictionary of peer_id -> player_info
var player_name = "Player"
var is_multiplayer = false
var game_in_progress = false

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ============= HOST GAME =============
func create_server(server_name: String = "Host") -> bool:
	player_name = server_name
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		print("Failed to create server: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	
	# Add host as a player
	players[1] = {
		"name": player_name,
		"id": 1
	}
	
	print("Server created on port ", PORT)
	return true


# ============= JOIN GAME =============
func join_server(address: String, client_name: String = "Client") -> bool:
	player_name = client_name
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	
	if error != OK:
		print("Failed to connect to server: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	
	print("Attempting to connect to ", address, ":", PORT)
	return true


# ============= DISCONNECT =============
func disconnect_from_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	players.clear()
	is_multiplayer = false
	game_in_progress = false
	print("Disconnected from multiplayer session")


# ============= NETWORK CALLBACKS =============
func _on_player_connected(id):
	print("Player connected: ", id)


func _on_player_disconnected(id):
	print("Player disconnected: ", id)
	if players.has(id):
		players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	print("Successfully connected to server!")
	# Register self with server
	var peer_id = multiplayer.get_unique_id()
	register_player.rpc_id(1, peer_id, player_name)


func _on_connected_fail():
	print("Failed to connect to server")
	multiplayer.multiplayer_peer = null
	is_multiplayer = false


func _on_server_disconnected():
	print("Server disconnected")
	multiplayer.multiplayer_peer = null
	is_multiplayer = false
	players.clear()
	server_disconnected.emit()


# ============= PLAYER REGISTRATION =============
@rpc("any_peer", "reliable")
func register_player(peer_id: int, p_name: String):
	players[peer_id] = {
		"name": p_name,
		"id": peer_id
	}
	
	print("Player registered: ", p_name, " (ID: ", peer_id, ")")
	player_connected.emit(peer_id, players[peer_id])
	
	# If we're the server, send back all existing players to the new client
	if multiplayer.is_server():
		sync_players.rpc_id(peer_id, players)


@rpc("authority", "reliable")
func sync_players(all_players: Dictionary):
	players = all_players
	print("Received player list: ", players)


# ============= UTILITY FUNCTIONS =============
func get_player_count() -> int:
	return players.size()


func get_player_name(peer_id: int) -> String:
	if players.has(peer_id):
		return players[peer_id]["name"]
	return "Unknown"


func is_server() -> bool:
	return multiplayer.is_server()


func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()


func is_multiplayer_active() -> bool:
	return is_multiplayer


# ============= GAME STATE =============
func start_multiplayer_game():
	"""Called when the host starts the game from lobby"""
	game_in_progress = true
	game_started.emit()
	print("Multiplayer game started!")
