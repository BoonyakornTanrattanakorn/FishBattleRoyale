extends Control

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var subtitle_label: Label = $Panel/VBoxContainer/Subtitle
@onready var time_label: Label = $Panel/VBoxContainer/StatsContainer/TimeValue
@onready var kills_label: Label = $Panel/VBoxContainer/StatsContainer/KillsValue
@onready var powerups_label: Label = $Panel/VBoxContainer/StatsContainer/PowerupsValue
@onready var main_menu_button: Button = $Panel/VBoxContainer/ButtonContainer/MainMenuButton
@onready var retry_button: Button = $Panel/VBoxContainer/ButtonContainer/RetryButton

func _ready() -> void:
	# Check if this is multiplayer win
	if GameStats.winner_id > 0:
		title_label.text = "Player " + str(GameStats.winner_id) + " Wins!"
		subtitle_label.text = "Victory in local multiplayer!"
		# Reset winner_id for next game
		GameStats.winner_id = 0
	
	# Display stats
	time_label.text = GameStats.get_time_formatted()
	kills_label.text = str(GameStats.kills)
	powerups_label.text = str(GameStats.powerups_collected)
	
	# Connect buttons
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/TestMap/test_map.tscn")
