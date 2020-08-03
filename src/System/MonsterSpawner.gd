extends Node

export(float) var min_size = 0.5
export(float) var max_size = 1.0
export(int) var min_activiness = 30
export(int) var max_activiness = 60
export(int) var min_aggressiveness = 30
export(int) var max_aggressiveness = 60
export(int) var min_move_speed = 80
export(int) var max_move_speed = 120
export(int) var max_monster_count = 50
export(float) var spawn_interval = 1.0
export(int) var map_size = 64 * 32

var _next_spawn = 1.0


onready var _monster_count = 0

func _physics_process(delta):
	if _monster_count >= max_monster_count:
		return;
	
	if _next_spawn > 0:
		_next_spawn -= delta
		return
	
	_next_spawn = spawn_interval
		
	_monster_count += 1
	
	var mob = load("res://assets/scenes/objects/monster.tscn").instance()
	
	mob.set("activiness", randi() % max_activiness + (max_activiness - min_activiness))
	mob.set("aggressiveness", randi() % max_aggressiveness + (max_aggressiveness - min_aggressiveness))
	mob.set("move_speed", randi() % max_move_speed + (max_move_speed - min_move_speed))
	mob.position.x = randi() % map_size
	mob.position.y = randi() % map_size
	
	var size = randf() * max_size + (max_size - min_size)
	
	var sprite = mob.get_node("Sprite")
	sprite.scale.x = size
	sprite.scale.y = size
	sprite.modulate = Color(randf() * 0.5 + 0.5, randf() * 0.5 + 0.5, randf() * 0.5 + 0.5)
	
	add_child(mob)
