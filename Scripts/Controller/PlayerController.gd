extends KinematicBody2D

export(int) var speed = 100
export(int) var speed_plus = 200

onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")

func get_input():
	var velocity = Vector2.ZERO
	velocity.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = velocity.normalized() * (speed_plus if Input.is_key_pressed(KEY_CONTROL) else speed)
	return velocity
	
func _physics_process(delta):
	var input_direction = get_input()
	
	if (input_direction != Vector2.ZERO):
		animation_tree.set("parameters/idle/blend_position", input_direction)
		animation_tree.set("parameters/walk/blend_position", input_direction)
		animation_state.travel("walk")
		var new_velocity = move_and_slide(input_direction)
	else:
		animation_state.travel("idle")
		animation_tree.set("parameters/idle/blend_position", input_direction)
	
#	if (new_velocity != velocity):
#		emit_signal("moving", velocity)
