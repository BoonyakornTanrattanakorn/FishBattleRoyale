extends Character
class_name Enemy

const DIRECTIONS = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN
]

@onready var bomb_placement_system: Node = $BombPlacementSystem

var think_time := 0.5


func _ready():
	super()
	ai_loop()


func ai_loop():
	while true:
		if !moving:
			think()
		await get_tree().create_timer(think_time).timeout


func think():
	var target: Character = get_closest_player()

	if target:
		chase(target)
	else:
		move(DIRECTIONS.pick_random())

	# Random bomb chance
	if randf() < 0.3:
		bomb_placement_system.place_bomb()


func chase(target: Character):
	var delta: Vector2 = target.position - position

	var dir: Vector2

	if abs(delta.x) > abs(delta.y):
		dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
	else:
		dir = Vector2.DOWN if delta.y > 0 else Vector2.UP

	move(dir)


func get_closest_player() -> Character:
	var players := get_tree().get_nodes_in_group("players")
	var closest: Character = null
	var best := INF

	for p in players:
		if p == self:
			continue

		var d := position.distance_squared_to(p.position)
		if d < best:
			best = d
			closest = p

	return closest
