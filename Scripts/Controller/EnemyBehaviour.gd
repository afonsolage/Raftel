extends KinematicBody2D

enum State {
	IDLING,
	WANDERING,
	MOVING,
	ATTACKING,
	RETURNING,
	DEAD,
}

export (State) var state = State.IDLING setget set_state
export (int) var activiness = 30
export (int) var aggressiveness = 80
export (int) var move_speed = 90
export (int) var move_range = 200
export (int) var max_range = 600
export (int) var attack_range = 40

onready var original_position = position
onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")

var idle_timeout = 0.0
var attack_timeout = 0.0

var target = Vector2.ZERO
var aggro_target = null

func set_state(value):
	if state == State.DEAD:
		return
	state = value

func _physics_process(delta):
	match self.state:
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
		State.DEAD:
			process_dead(delta)


func process_idling(delta):
	if position.distance_to(original_position) > max_range:
		self.state = State.RETURNING
		return

	idle_timeout -= delta

	if idle_timeout > 0:
		return

	self.state = get_random_wander_or_idle()

	if self.state == State.IDLING:
		idle_timeout = (1.0 - (activiness / 100.0)) * 5

func process_wandering(_delta):
	var x = (randi() % move_range) - (move_range / 2)
	var y = (randi() % move_range) - (move_range / 2)

	target = self.position + Vector2(x, y)

	self.state = State.MOVING


func process_moving(_delta):
	var dir = self.position.direction_to(target)

	if target.distance_to(self.position) < 1 :
		set_idle()
	else:
		if set_walk_to(dir) == false:
			set_idle()


func process_attacking(delta):
	if position.distance_to(aggro_target.position) > attack_range:
		if set_walk_to(position.direction_to(aggro_target.position)):
			return
			
	if attack_timeout <= 0:
		animation_tree.set("parameters/attack/blend_position", position.direction_to(aggro_target.position))
		animation_state.start("attack")
		attack_timeout = 1
	else:
		attack_timeout -= delta
		

func process_returning(_delta):
	var x = randi() % 30 - 15
	var y = randi() % 30 - 15

	target = Vector2(x + original_position.x, y + original_position.y)
	self.state = State.MOVING

func process_dead(_delta):
	pass

func get_random_wander_or_idle():
	var rnd = randi() % 100
	return State.WANDERING if rnd < activiness else State.IDLING

func set_idle():
	if aggro_target != null:
		self.state = State.ATTACKING
	else:
		self.state = State.IDLING
		
	animation_state.travel("idle")

func set_walk_to(dir):
	var moved = move_and_slide(dir * move_speed).length() > 0.1
	
	if moved:
		animation_tree.set("parameters/walk/blend_position", dir)
		animation_tree.set("parameters/idle/blend_position", dir)
	
		animation_state.travel("walk")
	
	return moved

func set_attacking():
	self.state = State.ATTACKING

func set_dead():
	self.state = State.DEAD
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = 5.0
	timer.connect("timeout", self, "queue_free")
	add_child(timer)
	animation_state.travel("Die")

func _on_HP_died():
	set_dead()

func _on_AggroArea_area_entered(area):
	if state == State.DEAD:
		return
		
	aggro_target = area.get_parent()
	set_attacking()

func _on_AggroArea_area_exited(_area):
	if state == State.DEAD:
		return
	
	aggro_target = null
	set_idle()
