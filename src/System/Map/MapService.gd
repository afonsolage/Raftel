extends Node

var _maps : Dictionary = {}

func get_map(point: Vector2) -> MapHeight:
	if _maps.has(point):
		return _maps[point]
	
	
	var generator := MapGenerator.new()
	#TODO: Configure generator
	
	var map_seed = int(point.x) << 32 | int(point.y)
	var map :MapHeight = generator.generate(map_seed)
	_maps[point] = map
	
	return map


