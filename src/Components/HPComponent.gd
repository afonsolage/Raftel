extends Node2D

signal died

export(int) var max_hp = 10

onready var hp = max_hp
onready var _hp_bar = $HPBar
onready var _hp_bar_full_size = _hp_bar.rect_size.x

func _on_HurtBox_area_entered(area):
	hp -= 3 #TODO: Add hit damage
	
	if hp <= 0:
		emit_signal("died")
		_hp_bar.visible = false
	else:
		_hp_bar.rect_size.x = _hp_bar_full_size * get_hp_rate()


func get_hp_rate():
	return float(hp) / float(max_hp)
