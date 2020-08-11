extends TileMap

export (int) var SIZE = 64
export (int) var OCTAVES = 2
export (float) var PERSISTENCE = 0.8
export (float) var PERIOD = 20.0
export (int) var WALL_SIZE = 3
export (float) var WALL_thickness = 1.0 / WALL_SIZE


enum TERRAIN_TYPE { GRASS, DIRT, SAND, ROCK, WATER }

func _ready():
	generate_base()


func generate_base():
	var mapService = get_node("/root/MapService")
	
	var map :MapHeight = mapService.get_map(Vector2(0, 10))

	for x in range(map._size):
		for y in range(map._size):
			var type = TERRAIN_TYPE.GRASS
	
			var h = map.get_at(x, y)
	
			if h < 0.1:
				type = TERRAIN_TYPE.WATER
			elif h < 0.3:
				type = TERRAIN_TYPE.SAND
			elif h < 0.5:
				type = TERRAIN_TYPE.GRASS
			elif h < 0.7:
				type = TERRAIN_TYPE.DIRT
			else:
				type = TERRAIN_TYPE.ROCK
	
			set_cell(x, y, type)

