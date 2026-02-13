extends Node2D

@onready var heartsContainer = $CanvasLayer/heartContainer
@onready var player = $Player
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	heartsContainer.setMaxHearts(3)
	heartsContainer.updateHearts(player.getHp())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
