extends TileMap

export (Vector2) var map_position = Vector2.ZERO
export (int) var size = 64
export (int) var octaves = 2
export (float) var persistence = 0.8
export (float) var period = 20.0
export (int) var wall_size = 3
export (float) var wall_thickness = 1.0 / wall_size


enum TERRAIN_TYPE { GRASS, DIRT, SAND, ROCK, WATER }

func _ready():
	generate_base()


func generate_base():
	var mapService = get_node("/root/MapService")

	var map :MapHeight = mapService.get_map(map_position)

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


