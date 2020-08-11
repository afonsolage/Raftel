tool
extends TileMap

export (bool) var dirty = false setget reload

export (int) var SIZE = 64
export (int) var OCTAVES = 2
export (float) var PERSISTENCE = 0.8
export (float) var PERIOD = 20.0
export (int) var WALL_SIZE = 3
export (float) var WALL_thickness = 1.0 / WALL_SIZE


func _ready():
	pass  # Replace with function body.


enum TERRAIN_TYPE { GRASS, DIRT, SAND, ROCK, WATER }


func reload(_value):
	dirty = false
	clear()
	generate_base()


func generate_base():
	var noise = OpenSimplexNoise.new()

	noise.seed = randi()
	noise.octaves = OCTAVES
	noise.period = PERIOD
	noise.persistence = PERSISTENCE

	for i in range(SIZE * SIZE):
		var x = i / SIZE
		var y = i % SIZE

		var h = noise.get_noise_2d(x, y)
		var type = TERRAIN_TYPE.GRASS

		h = apply_wall_height(x, y, h)

		if h < -0.8:
			type = TERRAIN_TYPE.WATER
		elif h < -0.5:
			type = TERRAIN_TYPE.SAND
		elif h < 0:
			type = TERRAIN_TYPE.GRASS
		elif h < 0.7:
			type = TERRAIN_TYPE.DIRT
		else:
			type = TERRAIN_TYPE.ROCK

		set_cell(x, y, type)


func apply_wall_height(x, y, h):
	if x >= WALL_SIZE && x <= SIZE - 1 - WALL_SIZE && y >= WALL_SIZE && y <= SIZE - 1 - WALL_SIZE:
		return h

	var x_dif = 0

	if x < WALL_SIZE:
		x_dif = WALL_SIZE - x
	elif x > SIZE - 1 - WALL_SIZE:
		x_dif = x - (SIZE - 1 - WALL_SIZE)

	var y_dif = 0

	if y < WALL_SIZE:
		y_dif = WALL_SIZE - y
	elif y > SIZE - 1 - WALL_SIZE:
		y_dif = y - (SIZE - 1 - WALL_SIZE)

	return h + (max(x_dif, y_dif) * WALL_thickness)
