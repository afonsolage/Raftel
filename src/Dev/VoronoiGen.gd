tool
extends Sprite

export(bool) var dirty := false setget reload
# export(bool) var expand_right := false setget expand_right

export(int) var size := 300
export(int) var num_cells := 20
export(int) var expand_cell := 10

var _points = []
var _colors = []

func reload(_value):
	dirty = false
	_points = []
	_colors = []
	generate_voronoi_diagram()
#
#func expand_right(_value):
#	expand_right = false
#
#	var img: Image = texture.get_data() as Image
#	img.resize(size + expand_cell, size)
#
#	for i in range(expand_cell):
#		_points.push_back(Vector2(int(randf() * expand_cell + size), int(randf() * expand_cell + size)))
#
#		randomize()
#		_colors.push_back(Color(randf(), randf(), randf(), 1))
#
#	for y in range(size + expand_cell):
#		for x in range(size + expand_cell):
#			var closest_point = img.get_size().length()
#			var j = -1
#			for i in range(num_cells + expand_cell):
#				var d = (_points[i] - Vector2(x, y)).length()
#				if d < closest_point:
#					closest_point = d
#					j = i
#			img.lock()
#			img.set_pixel(x, y, _colors[j])
#			img.unlock()
#
#	var texture = ImageTexture.new()
#	texture.create_from_image(img)
#	texture.flags = 0
#	self.set_texture(texture)
#
#
#	pass

# Got from https://www.reddit.com/r/godot/comments/bazs8m/quick_voronoi_diagram/
func generate_voronoi_diagram():
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)

	for i in range(num_cells):
		_points.push_back(Vector2(int(randf()*size), int(randf()*size)))
		
		randomize()
		_colors.push_back(Color(randf(), randf(), randf(), 1))
		
	for y in range(size):
		for x in range(size):
			var closest_point = img.get_size().length()
			var j = -1
			for i in range(num_cells):
				var d = (_points[i] - Vector2(x, y)).length()
				if d < closest_point:
					closest_point = d
					j = i
			img.lock()
			img.set_pixel(x, y, _colors[j])
			img.unlock()

	
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	texture.flags = 0
	self.set_texture(texture)
