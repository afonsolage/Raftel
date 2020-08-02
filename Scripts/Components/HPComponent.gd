extends Node2D

export(int) var max_hp = 10

signal died

onready var hp = max_hp
onready var hp_bar = $HPBar
onready var hp_bar_full_size = hp_bar.rect_size.x


func _on_HurtBox_area_entered(area):
	hp -= 3 #TODO: Add hit damage
	
	if hp <= 0:
		emit_signal("died")
		hp_bar.visible = false
	else:
		hp_bar.rect_size.x = hp_bar_full_size * get_hp_rate()
		
func get_hp_rate():
	return float(hp) / float(max_hp)
