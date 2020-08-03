extends KinematicBody2D

enum State {
	IDLING,
	WALKING,
	ATTACKING,
	DIED,
}

export(int) var speed = 100
export(int) var speed_plus = 200

var _input_direction = Vector2.ZERO
var _input_action = false

onready var _animation_tree = $AnimationTree
onready var _animation_state = _animation_tree.get("parameters/playback")
onready var _state = State.IDLING


func process_input():
	var velocity = Vector2.ZERO
	velocity.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = velocity.normalized() * (speed_plus if Input.is_key_pressed(KEY_CONTROL) else speed)
	_input_direction = velocity
	
	_input_action = Input.is_action_just_pressed("ui_action")


func _physics_process(delta):
	process_input()
	
	if _state == State.ATTACKING || _state == State.DIED:
		return
	
	if _input_action:
		set_attacking()
	elif _input_direction != Vector2.ZERO:
		set_walking()
	elif _state != State.IDLING:
		set_idle()


func set_idle():
	_state = State.IDLING
	_animation_state.travel("idle")


func set_walking():
	_state = State.WALKING
	_animation_tree.set("parameters/idle/blend_position", _input_direction)
	_animation_tree.set("parameters/walk/blend_position", _input_direction)
	_animation_tree.set("parameters/attack/blend_position", _input_direction)
	_animation_state.travel("walk")
	var new_velocity = move_and_slide(_input_direction) * 2
	
	if new_velocity.length() < 0.1:
		set_idle()


func set_attacking():
	_state = State.ATTACKING
	_animation_state.travel("attack")


func set_died():
	_state = State.DIED
	_animation_state.travel("Die")


func attack_finished():
	set_idle()


func _on_HP_died():
	set_died()

