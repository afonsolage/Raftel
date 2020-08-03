tool
extends EditorScript


func _run():
	var root = get_scene()
	
	for n in root.get_children():
		root.remove_child(n)
		n.queue_free()

