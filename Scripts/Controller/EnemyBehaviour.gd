extends KinematicBody2D

enum State {
	IDLING,
	WANDERING,
	MOVING,
	ATTACKING,
	RETURNING,
}

export (State) var state = State.IDLING
export (int) var activiness = 30
export (int) var aggressiveness = 80
export (int) var move_speed = 90
export (int) var move_range = 200
export (int) var max_range = 600

onready var original_position = position
onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")

var idling_timeout = 0
var target = Vector2.ZERO


func _physics_process(delta):
	match state:
		State.IDLING:
			process_idling(delta)
		State.WANDERING:
			process_wandering(delta)
		State.ATTACKING:
			process_attacking(delta)
		State.MOVING:
			process_moving(delta)
		State.RETURNING:
			process_returning(delta)


func process_idling(delta):
	if position.distance_to(original_position) > max_range:
		state = State.RETURNING
		return

	idling_timeout -= delta

	if idling_timeout > 0:
		return

	state = get_random_wander_or_idle()

	if state == State.IDLING:
		idling_timeout = (1.0 - (activiness / 100.0)) * 5

func process_wandering(_delta):
	var x = (randi() % move_range) - (move_range / 2)
	var y = (randi() % move_range) - (move_range / 2)

	target = self.position + Vector2(x, y)

	state = State.MOVING


func process_moving(_delta):
	var dir = self.position.direction_to(target)

	if target.distance_to(self.position) < 1 :
		set_idle()
	else:
		set_walk_to(dir)


func process_attacking(_delta):
	pass


func process_returning(_delta):
	var x = randi() % 30 - 15
	var y = randi() % 30 - 15

	target = Vector2(x + original_position.x, y + original_position.y)
	state = State.MOVING


func get_random_wander_or_idle():
	var rnd = randi() % 100
	return State.WANDERING if rnd < activiness else State.IDLING

func set_idle():
	state = State.IDLING
	animation_state.travel("idle")

func set_walk_to(dir):
	animation_tree.set("parameters/walk/blend_position", dir)
	animation_tree.set("parameters/idle/blend_position", dir)

	animation_state.travel("walk")
	var moved = move_and_slide(dir * move_speed)

	if moved.length() < 0.1:
		set_idle()
