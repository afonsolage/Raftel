tool

extends Sprite

export(bool) var dirty := false setget reload
export(bool) var is_generate_terrain := true
export(bool) var is_generate_border := true
export(bool) var is_generate_places := true
export(bool) var is_connect_places := true
export(bool) var is_smooth_connection_border := true
export(bool) var is_colorize_map := true

export(int) var size := 256
export(int) var octaves := 2
export(float) var persistance := 0.3
export(float) var period := 20.0
export(int) var border_size := 30
export(float) var border_thickness := 0.05
export(bool) var border_montains := true
export(int) var border_connection_size := 20
export(int) var places_count := 5
export(int) var places_path_noise_rate := 40
export(int) var places_path_thickness := 5

export(bool) var disable_randomness := false

func reload(_value):
	var generator = MapGenerator.new()
	generator.is_generate_terrain = is_generate_terrain
	generator.is_generate_border = is_generate_border
	generator.is_generate_places = is_generate_places
	generator.is_connect_places = is_connect_places
	generator.is_smooth_connection_border = is_smooth_connection_border
	
	generator.size = size
	generator.octaves = octaves
	generator.persistance = persistance
	generator.period = period
	generator.border_size = border_size
	generator.border_thickness = border_thickness
	generator.border_montains = border_montains
	generator.border_connection_size = border_connection_size
	generator.places_count = places_count
	generator.places_path_noise_rate = places_path_noise_rate
	generator.places_path_thickness = places_path_thickness
	
	generator.disable_randomness = disable_randomness
	
	generator.generate()
	
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	
	draw_map(img, generator)
		
	
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	texture.flags = 0
	self.set_texture(texture)


func draw_map(img: Image, generator: MapGenerator) -> void:
	img.lock()
	for x in img.get_size().x:
		for y in img.get_size().y:
			var h = generator.height_at(x, y)
			var color = height_to_color(h)
			img.set_pixel(x, y, color)
	img.unlock()


func height_to_color(height: float) -> Color:
	if not is_colorize_map:
		return Color(height, height, height)
	
	if height < 0.2:
		return Color.blue
	elif height < 0.45:
		return Color.orange
	elif height < 0.55:
		return Color.yellow
	elif height < 0.8:
		return Color.green
	elif height < 0.9:
		return Color.gray
	else:
		return Color.white
