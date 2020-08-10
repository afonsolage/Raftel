tool

extends Sprite

export(bool) var dirty := false setget reload
export(bool) var generate_terrain := true
export(bool) var generate_border := true
export(bool) var generate_places := true
export(bool) var connect_places := true
export(bool) var smooth_connection_border := true

export(int) var size := 300
export(int) var octaves := 2
export(float) var persistance := 0.3
export(float) var period := 20.0
export(int) var border_size := 30
export(int) var border_tickness := 0.3
export(bool) var border_montains := true
export(int) var border_connection_size := 15
export(int) var places_count := 10

const DIRS := [Vector2(1,0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]

var _astar = AStar2D.new()

func reload(_value):
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	
	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			var point = Vector2(x, y)
			_astar.add_point(calc_point_index(point), point)
	
	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			var point = Vector2(x, y)
			for dir in DIRS:
				var neighbor = point + dir
				if _astar.has_point(calc_point_index(neighbor)):
					_astar.connect_points(calc_point_index(point), calc_point_index(neighbor))
	
	if generate_terrain:
		generate_terrain(img)
	
	if generate_border:
		generate_border(img)
	
	if generate_places:
		generate_places(img)
	
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


func generate_places(img: Image) -> void:
	var offset = size / 15
	var places := []
	
	for i in range(places_count):
		var x = randi() % (size - offset * 3) + offset
		var y = randi() % (size - offset * 3) + offset
		var w = randi() % offset * 2 + offset
		var h = randi() % offset * 2 + offset
		
		create_square(x, y, w, h, img)
		places.push_back(Vector2(int(x + w / 2), int(y + h / 2)))

	if connect_places:
		connect_places(places, img)


func create_square(sx: int, sy: int, swidth: int, sheight: int, img: Image) -> void:
	var rect := Rect2(sx, sy, swidth, sheight)
	var img_rect = img.get_used_rect()
	var half_size:Vector2 = (rect.end - rect.position) / 2
	var center := Vector2(rect.position.x + int(half_size.x), rect.position.y + int(half_size.y))
		
	if not img_rect.encloses(rect):
		return
	
	var sborder_tickness := int(float((swidth + sheight) / 2 / 5.0))
	var border_rect = Rect2(rect.position.x - sborder_tickness, 
		rect.position.y - sborder_tickness,  
		rect.end.x + (sborder_tickness * 2) - 1, 
		rect.end.y + (sborder_tickness * 2) - 1)
	
	for pixel_x in range(rect.position.x, rect.end.x):
		for pixel_y in range(rect.position.y, rect.end.y):
			var pixel_point = Vector2(pixel_x, pixel_y)
			
			if not img_rect.has_point(pixel_point):
				continue
			
			img.lock()
			var h := img.get_pixel(pixel_x, pixel_y).r
			var dist :float = (pixel_point - center).length()
			var diff :float = (half_size.length() - dist) / half_size.length()
			var diff_h = h - 0.5
			h -= diff_h * diff #TODO Find a better way to place this const
			img.set_pixel(pixel_x, pixel_y, Color(h, h, h))
			img.unlock()

	if smooth_connection_border:
		var point := center
		var count := 0
		var walk_left := 1
		
		var dir_cnt := 0
		var dir: Vector2 = DIRS[dir_cnt]
		var dir_mod := 0
		
		while border_rect.has_point(point):
			if img_rect.has_point(point) && not rect.has_point(point):
				smooth_pixel(point.x, point.y, img)
			
			count += 1
			walk_left -= 1
			
			if walk_left <= 0:
				dir_mod += 1
				dir = DIRS[dir_mod % 4]
				
				dir_cnt += (1 if dir_mod % 2 == 1 else 0)
				walk_left = dir_cnt
			
			point += dir


func smooth_pixel(x: int, y: int, img: Image) -> void:
	var img_rect = img.get_used_rect()
	var h := 0.0
	var count := 0
	
	img.lock()
	
	for i in range (-1, 2):
		for k in range (-1, 2):
			var point = Vector2(x + i, y + k)
			
			if not img_rect.has_point(point):
				continue
	
			h += img.get_pixel(point.x, point.y).r
			count += 1
	
	
	
	img.set_pixel(x, y, Color(h / count, h / count, h / count))
	img.unlock()


func connect_places(places, img: Image) -> void:
	var places_with_length = []
	for p in places:
		places_with_length.push_back([p, p.length()])
	
	places_with_length.sort_custom(self, "sort_by_distance")
	
	for i in range(places_with_length.size()):
		var origin := Vector2.ZERO
		var dest := Vector2.ZERO
		if i < places.size() - 1:
			origin = places[i]
			dest = places[i+1]
		else:
			origin = places[i]
			dest = places[0]
		
		generate_path(origin, dest, img)


static func sort_by_distance(a, b) -> bool:
	if a[1] < b[1]:
		return true
	else:
		return false


func generate_path(origin: Vector2, dest: Vector2, img: Image) -> void:
	var points = _astar.get_point_path(calc_point_index(origin), calc_point_index(dest))
	
	for point in points:
		img.lock()
		img.set_pixel(point.x, point.y, Color(0.5, 0.5, 0.5))
		for dir in DIRS:
			for i in range(1, 5):
				img.set_pixel(point.x + (dir.x * i), point.y + (dir.y * i), Color(0.5, 0.5, 0.5))
		img.unlock()

	for point in points:
		img.lock()
		for dir in DIRS:
			for i in range(1, 5):
				smooth_pixel(point.x + (dir.x * i), point.y + (dir.y * i), img)
		img.unlock()


func calc_point_index(point: Vector2) -> int:
	return int(point.x) * size + int(point.y)
