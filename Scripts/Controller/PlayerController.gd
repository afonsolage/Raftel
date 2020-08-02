extends KinematicBody2D

export(int) var speed = 100
export(int) var speed_plus = 200

onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var state = State.IDLING

var input_direction = Vector2.ZERO
var input_action = false

enum State {
	IDLING,
	WALKING,
	ATTACKING,
}

func process_input():
	var velocity = Vector2.ZERO
	velocity.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = velocity.normalized() * (speed_plus if Input.is_key_pressed(KEY_CONTROL) else speed)
	input_direction = velocity
	
	input_action = Input.is_action_just_pressed("ui_action")
	
func _physics_process(delta):
	process_input()
	
	if state == State.ATTACKING:
		return
	
	if input_action:
		set_attacking()
	elif input_direction != Vector2.ZERO:
		set_walking()
	elif state != State.IDLING:
		set_idle()

func set_idle():
	state = State.IDLING
	animation_state.travel("idle")
	
func set_walking():
	state = State.WALKING
	animation_tree.set("parameters/idle/blend_position", input_direction)
	animation_tree.set("parameters/walk/blend_position", input_direction)
	animation_tree.set("parameters/attack/blend_position", input_direction)
	animation_state.travel("walk")
	var new_velocity = move_and_slide(input_direction)
	
	if new_velocity.length() < 0.1:
		set_idle()

func set_attacking():
	state = State.ATTACKING
	animation_state.travel("attack")
	
func attack_finished():
	set_idle()
