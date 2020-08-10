tool

extends Sprite

export(bool) var dirty := false setget reload
export(bool) var generate_terrain := true
export(bool) var generate_border := true
export(bool) var generate_places := true
export(bool) var connect_places := true
export(bool) var smooth_connection_border := true
export(bool) var colorize_map := true

export(int) var size := 300
export(int) var octaves := 2
export(float) var persistance := 0.3
export(float) var period := 20.0
export(int) var border_size := 30
export(int) var border_tickness := 0.3
export(bool) var border_montains := true
export(int) var border_connection_size := 15
export(int) var places_count := 10
export(int) var places_path_noise_rate := 30
export(int) var places_path_tickness := 5

const DIRS := [Vector2(1,0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]

func reload(_value):
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	
	if generate_terrain:
		generate_terrain(img)
	
	if generate_border:
		generate_border(img)
	
	if generate_places:
		generate_places(img)
	
	if colorize_map:
		colorize_map(img)
	
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
	
	
	var first_connection_generated := false
	
	var dir_idx = randi() % 4
	var dir:Vector2 = DIRS[dir_idx]
	var connections := []
	
	for i in range(DIRS.size()):
		if not first_connection_generated or randi() % 100 > 30:
			first_connection_generated = true
			connections.push_back(dir)
			dir_idx = (dir_idx + 1) % DIRS.size()
			dir = DIRS[dir_idx]
		
	
	for connection_dir in connections:
		var max_offset := size - (border_connection_size * 3)
		var rnd := (randi() % max_offset) + border_connection_size
		
		var x = rnd if connection_dir.x == 0 else 0 if connection_dir.x == -1 else size - border_connection_size - 1
		var y = rnd if connection_dir.y == 0 else 0 if connection_dir.y == -1 else size - border_connection_size - 1
		
		create_square(x, y, border_connection_size, border_connection_size, img, true)
		var center = Vector2(int(x + border_connection_size / 2), int(y + border_connection_size / 2))
		places.push_back(center)
	
	for i in range(places_count):
		var x = randi() % (size - offset * 3) + offset
		var y = randi() % (size - offset * 3) + offset
		var w = randi() % offset * 2 + offset
		var h = randi() % offset * 2 + offset
		
		create_square(x, y, w, h, img)
		places.push_back(Vector2(int(x + w / 2), int(y + h / 2)))

	if connect_places:
		connect_places(places, img)


func create_square(sx: int, sy: int, swidth: int, sheight: int, img: Image, connection := false) -> void:
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
		
	var connection_rect :Rect2 = img_rect.grow(-border_connection_size/2)
	
	for pixel_x in range(rect.position.x, rect.end.x):
		for pixel_y in range(rect.position.y, rect.end.y):
			var pixel_point = Vector2(pixel_x, pixel_y)
			
			if not img_rect.has_point(pixel_point):
				continue
			
			img.lock()
			var h := 0.5 #TODO Find a better way to place this const
			
			if not connection or connection_rect.has_point(pixel_point):
				h = img.get_pixel(pixel_x, pixel_y).r
				var dist :float = (pixel_point - center).length()
				var diff :float = (half_size.length() - dist) / half_size.length()
				var diff_h = h - 0.5
				h -= diff_h * diff 
				
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
	
	
	if count > 0 :
		img.set_pixel(x, y, Color(h / count, h / count, h / count))
	img.unlock()

class DistanceSorter:
	var target := Vector2.ZERO
	
	func sort(a, b):
		if (target - a).length() < (target - b).length():
			return true
		else:
			return false

func connect_places(places, img: Image) -> void:
	while not places.empty():
		var point = places.pop_back();
		
		if places.empty():
			return
		
		var sorter := DistanceSorter.new()
		sorter.target = point
		places.sort_custom(sorter, "sort")
		generate_path(point, places.front(), img)


static func sort_by_distance(a, b) -> bool:
	if a[1] < b[1]:
		return true
	else:
		return false


func generate_path(origin: Vector2, dest: Vector2, img: Image) -> void:
	var queue = []
	var walked = []
	queue.push_back([origin, calc_distance_length(origin, dest)])
	
	var sanity_check := 1000
	
	while not queue.empty():
		sanity_check -= 1
		if sanity_check < 0:
			print("Sanity failed. Queue size: %d" % queue.size())
			return
		
		var point = queue.pop_front()[0]
		
		walked.push_front(point)
		
		if point == dest:
			draw_path(walked, img)
			return

		var added_noise := false

		for dir in DIRS:
			var next_point :Vector2 = point + dir
			
			if not added_noise && randi() % 100 < places_path_noise_rate:
				added_noise = true
				continue
				
			if not walked.has(next_point):
				queue.push_back([next_point, calc_distance_length(next_point, dest)])
		
		queue.sort_custom(self, "sort_by_distance")


func draw_path(path, img: Image) -> void:
	var img_rect = img.get_used_rect()
	img.lock()
	
	for p in path:
		for dir in DIRS:
			for i in range(1, places_path_tickness):
				var pixel = p + (dir * i)
				if img_rect.has_point(pixel):
					img.set_pixel(pixel.x, pixel.y, Color(0.5, 0.5, 0.5))
	
	for p in path:
		for dir in DIRS:
			for i in range(1, int(places_path_tickness * 2)):
				var pixel = p + (dir * i)
				if img_rect.has_point(pixel):
					smooth_pixel(pixel.x, pixel.y, img)
	
	img.unlock()


func calc_point_index(point: Vector2) -> int:
	return int(point.x) * size + int(point.y)


func calc_distance_length(a: Vector2, b: Vector2) -> float:
	return (a-b).length()


func colorize_map(img: Image) -> void:
	img.lock()
	for x in img.get_size().x:
		for y in img.get_size().y:
			var h = img.get_pixel(x, y).r
			var color = height_to_color(h)
			img.set_pixel(x, y, color)
	img.unlock()


func height_to_color(height: float) -> Color:
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
