tool
extends Sprite

export(bool) var dirty := false setget reload
export(int) var size := 300
export(int) var num_cells := 20

func reload(_value):
	dirty = false
	generate_voronoi_diagram()

# Got from https://www.reddit.com/r/godot/comments/bazs8m/quick_voronoi_diagram/
func generate_voronoi_diagram():
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)

	var points = []
	var colors = []
	
	for i in range(num_cells):
		points.push_back(Vector2(int(randf()*img.get_size().x), int(randf()*img.get_size().y)))
		
		randomize()
		colors.push_back(Color(randf(), randf(), randf(), 1))
		
	for y in range(img.get_size().y):
		for x in range(img.get_size().x):
			var dmin = img.get_size().length()
			var j = -1
			for i in range(num_cells):
				var d = (points[i] - Vector2(x, y)).length()
				if d < dmin:
					dmin = d
					j = i
			img.lock()
			img.set_pixel(x, y, colors[j])
			img.unlock()

	
	var texture = ImageTexture.new()
	texture.flags = Texture.FLAG_FILTER
	texture.create_from_image(img)
	self.set_texture(texture)
