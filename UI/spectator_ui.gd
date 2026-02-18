extends CanvasLayer

func _ready() -> void:
	print("Spectator UI active. Press ESC to return to main menu.")

func _process(delta: float) -> void:
	# Allow exiting to main menu
	if Input.is_action_just_pressed("ui_cancel"):
		# Reset session state when returning to menu
		GameStats.reset_session_state()
		# Disconnect from multiplayer
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = null
		# Remove this UI before changing scenes
		queue_free()
		get_tree().change_scene_to_file("res://UI/main_menu.tscn")
