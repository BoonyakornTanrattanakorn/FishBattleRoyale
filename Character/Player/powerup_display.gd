extends HBoxContainer

@onready var bomb_count: Label = $BombCount/Value
@onready var fire_count: Label = $FireCount/Value
@onready var speed_count: Label = $SpeedCount/Value

func _ready() -> void:
	update_display(0, 0, 0)

func update_display(bomb_ups: int, fire_ups: int, speed_ups: int) -> void:
	bomb_count.text = str(bomb_ups)
	fire_count.text = str(fire_ups)
	speed_count.text = str(speed_ups)
