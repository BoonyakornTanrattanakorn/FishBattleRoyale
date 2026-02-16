extends Control

@onready var map_width_input: SpinBox = $Panel/VBoxContainer/MapSizeContainer/MapWidthInput
@onready var map_height_input: SpinBox = $Panel/VBoxContainer/MapSizeContainer/MapHeightInput
@onready var enemy_count_input: SpinBox = $Panel/VBoxContainer/EnemyContainer/EnemyCountInput
@onready var difficulty_option: OptionButton = $Panel/VBoxContainer/DifficultyContainer/DifficultyOption
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

func _ready() -> void:
	# Load current settings
	map_width_input.value = Config.map_size.x
	map_height_input.value = Config.map_size.y
	enemy_count_input.value = Config.enemy_count
	
	# Setup difficulty dropdown
	difficulty_option.clear()
	difficulty_option.add_item("Easy")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Hard")
	
	match Config.difficulty:
		"Easy":
			difficulty_option.selected = 0
		"Normal":
			difficulty_option.selected = 1
		"Hard":
			difficulty_option.selected = 2
	
	# Connect signals
	map_width_input.value_changed.connect(_on_map_width_changed)
	map_height_input.value_changed.connect(_on_map_height_changed)
	enemy_count_input.value_changed.connect(_on_enemy_count_changed)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	back_button.pressed.connect(_on_back_pressed)

func _on_map_width_changed(value: float) -> void:
	Config.map_size.x = int(value)

func _on_map_height_changed(value: float) -> void:
	Config.map_size.y = int(value)

func _on_enemy_count_changed(value: float) -> void:
	Config.enemy_count = int(value)

func _on_difficulty_selected(index: int) -> void:
	match index:
		0:
			Config.set_difficulty("Easy")
		1:
			Config.set_difficulty("Normal")
		2:
			Config.set_difficulty("Hard")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
