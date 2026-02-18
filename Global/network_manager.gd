extends Node

# Network manager singleton for handling multiplayer state

signal player_spawned(peer_id: int, spawn_position: Vector2)
signal player_despawned(peer_id: int)

var players_data := {}  # peer_id -> {name: String, node: Node}
var spawn_positions := []

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("NetworkManager: Peer connected ", id)

func _on_peer_disconnected(id: int) -> void:
	print("NetworkManager: Peer disconnected ", id)
	players_data.erase(id)
	player_despawned.emit(id)

func register_player(peer_id: int, player_node: Node) -> void:
	if not players_data.has(peer_id):
		players_data[peer_id] = {}
	if typeof(players_data[peer_id]) == TYPE_DICTIONARY:
		players_data[peer_id]["node"] = player_node
	else:
		players_data[peer_id] = {"node": player_node}
	print("Registered player node: ", peer_id)

func get_player(peer_id: int) -> Node:
	var data = players_data.get(peer_id)
	if typeof(data) == TYPE_DICTIONARY:
		return data.get("node")
	return data

func get_player_name(peer_id: int) -> String:
	var data = players_data.get(peer_id)
	if typeof(data) == TYPE_DICTIONARY:
		return data.get("name", "Player %d" % peer_id)
	return "Player %d" % peer_id

func is_multiplayer() -> bool:
	return multiplayer.has_multiplayer_peer()

func is_server() -> bool:
	return multiplayer.is_server()
