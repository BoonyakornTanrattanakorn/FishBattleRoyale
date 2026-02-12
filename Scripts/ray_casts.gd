extends Node2D

class_name Raycasts

@onready var left_horizontal_raycasts: Array[RayCast2D] = [
	$Horizontal/Left/LeftHorizontalTop,
	$Horizontal/Left/LeftHorizontalBottom
]
@onready var right_horizontal_raycasts: Array[RayCast2D] = [
	$Horizontal/Right/RightHorizontalTop,
	$Horizontal/Right/RightHorizontalBottom
]
@onready var top_vertical_raycasts: Array[RayCast2D] = [
	$Vertical/Top/TopVerticalRight,
	$Vertical/Top/TopVerticalLeft
]
@onready var bottom_vertical_raycasts: Array[RayCast2D] = [
	$Vertical/Bottom/BottomVerticalRight,
	$Vertical/Bottom/BottomVerticalLeft
]

func check_collisions() -> Array[Vector2]:
	var collisions: Array[Vector2] = []
	
	var is_left_colliding = left_horizontal_raycasts.reduce(is_raycast_colliding, false)
	if(is_left_colliding):
		collisions.append(Vector2.LEFT)
		
	var is_right_colliding = right_horizontal_raycasts.reduce(is_raycast_colliding, false)
	if(is_right_colliding):
		collisions.append(Vector2.RIGHT)
		
	var is_top_colliding = top_vertical_raycasts.reduce(is_raycast_colliding, false)
	if(is_top_colliding):
		collisions.append(Vector2.UP)
		
	var is_bottom_colliding = bottom_vertical_raycasts.reduce(is_raycast_colliding, false)
	if(is_bottom_colliding):
		collisions.append(Vector2.DOWN)
		
	return collisions
	
func is_raycast_colliding(acc: bool, next: RayCast2D):
	return next.is_colliding() || acc
