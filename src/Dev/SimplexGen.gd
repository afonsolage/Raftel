tool

extends Sprite

export(bool) var dirty := false setget reload
export(bool) var generate_terrain := true
export(bool) var generate_border := true

export(int) var size := 300
export(int) var octaves := 2
export(float) var persistance := 0.3
export(float) var period := 20.0
export(int) var border_size := 30
export(int) var border_tickness := 0.3
export(bool) var border_montains := true

func reload(_value):
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	
	if generate_terrain:
		generate_terrain(img)
	
	if generate_border:
		generate_border(img)
	
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	texture.flags = 0
	self.set_texture(texture)


func generate_terrain(img: Image) -> void:
	var noise = OpenSimplexNoise.new()
	
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance

	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			var h = (noise.get_noise_2d(x, y) + 1) / 2
			
			img.lock()
			img.set_pixel(x, y, Color(h, h, h))
			img.unlock()


func generate_border(img: Image) -> void:
	var border_left := border_size
	var border_up := border_size
	var border_right := img.get_size().x - border_size
	var border_down := img.get_size().y - border_size
	
	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			if x > border_left && x < border_right && y > border_up && y < border_down:
				continue
			
			var border_tickness_x := 0
			
			if x < border_left:
				border_tickness_x = border_left - x
			elif x > border_right:
				border_tickness_x = x - border_right
			
			var border_tickness_y := 0
			
			if y < border_up:
				border_tickness_y = border_up - y
			elif y > border_down:
				border_tickness_y = y - border_down
			
			img.lock()
			
			var h := img.get_pixel(x, y).r
			h += max(border_tickness_x, border_tickness_y) * (border_tickness * (1 if border_montains else -1))
			
			img.set_pixel(x, y, Color(h, h, h))
			img.unlock()
