extends Node2D

@onready var background_texture: TextureRect = $Background/BackgroundTexture
@onready var play_button: Button = $CanvasLayer/MenuContainer/PlayButton
@onready var settings_button: Button = $CanvasLayer/MenuContainer/SettingsButton
@onready var quit_button: Button = $CanvasLayer/MenuContainer/QuitButton
@onready var camera: Camera2D = $Camera2D

var enemy_scene := preload("res://Character/Enemy/enemy.tscn")
var wall_tile := preload("res://Block/Indestructible/Wall/wall.tscn")
var coral_tile := preload("res://Block/Destructible/Coral/coral.tscn")

var map_size := Vector2i(20, 20)
var coral_chance := 0.2
var enemy_count := 8

var camera_move_duration := 5.0
var camera_wait_time := 2.0

func _ready() -> void:
	randomize()
	
	# Generate background
	background_texture.visible = false
	
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := background_texture.duplicate() as TextureRect
			tile.visible = true
			var pos = Vector2(x, y) * Config.tile_size
			tile.position = pos
			$Background.add_child(tile)
			
			# Border walls
			if x == 0 or x == map_size.x - 1 or y == 0 or y == map_size.y - 1:
				var wall := wall_tile.instantiate()
				wall.position = pos
				add_child(wall)
			# Interior coral
			elif randf() < coral_chance:
				var coral := coral_tile.instantiate()
				coral.position = pos
				add_child(coral)
	
	# Wait for physics to update before spawning enemies
	await get_tree().physics_frame
	
	# Spawn enemies
	spawn_enemies()
	
	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Start camera movement
	start_camera_movement()


func spawn_enemies() -> void:
	for i in range(enemy_count):
		var enemy := enemy_scene.instantiate()
		
		# Find a random valid spawn position (no walls/coral)
		var spawn_x: int
		var spawn_y: int
		var attempts := 0
		const MAX_ATTEMPTS := 100
		
		# Keep trying until we find a clear spot
		while attempts < MAX_ATTEMPTS:
			spawn_x = randi_range(1, map_size.x - 2)
			spawn_y = randi_range(1, map_size.y - 2)
			
			# Check if position is clear (no blocks)
			var spawn_pos = Vector2(spawn_x, spawn_y) * Config.tile_size
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsPointQueryParameters2D.new()
			query.position = spawn_pos + Vector2(Config.tile_size / 2, Config.tile_size / 2)
			query.collision_mask = 1  # Check for blocks
			query.collide_with_areas = false
			query.collide_with_bodies = true
			
			var result := space_state.intersect_point(query)
			if result.is_empty():
				# Position is clear
				enemy.position = spawn_pos
				enemy.menu_mode = true  # Disable bombs in menu
				add_child(enemy)
				break
			
			attempts += 1


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Map/TestMap/test_map.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/settings_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func start_camera_movement() -> void:
	# Set initial camera position
	camera.position = get_random_camera_position()
	camera_movement_loop()


func camera_movement_loop() -> void:
	while true:
		await get_tree().create_timer(camera_wait_time).timeout
		
		var target_pos := get_random_camera_position()
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(camera, "position", target_pos, camera_move_duration)
		await tween.finished


func get_random_camera_position() -> Vector2:
	# Keep camera within map bounds with some margin
	var margin := 3
	var x := randi_range(margin, map_size.x - margin)
	var y := randi_range(margin, map_size.y - margin)
	return Vector2(x, y) * Config.tile_size
