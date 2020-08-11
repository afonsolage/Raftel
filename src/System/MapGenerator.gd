class_name MapGenerator

const DIRS := [Vector2(1,0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]

export(bool) var is_generate_terrain := true
export(bool) var is_generate_border := true
export(bool) var is_generate_places := true
export(bool) var is_connect_places := true
export(bool) var is_smooth_connection_border := true

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

var _buffer := []

func generate():
	_buffer.resize(size * size)
	
	if is_generate_terrain:
		generate_terrain()
	
	if is_generate_border:
		generate_border()
	
	if is_generate_places:
		generate_places()
	

func generate_terrain() -> void:
	var noise = OpenSimplexNoise.new()
	
	if disable_randomness:
		seed(1)
		
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance

	for x in range(size):
		for y in range(size):
			var h = (noise.get_noise_2d(x, y) + 1) / 2
			
			var idx = calc_point_index(x, y)
			_buffer[idx] = h


func generate_border() -> void:
	var border_left := border_size
	var border_up := border_size
	var border_right := size - border_size
	var border_down := size - border_size
	
	for x in range(size):
		for y in range(size):
			if x > border_left && x < border_right && y > border_up && y < border_down:
				continue
			
			var border_thickness_x := 0
			
			if x < border_left:
				border_thickness_x = border_left - x
			elif x > border_right:
				border_thickness_x = x - border_right
			
			var border_thickness_y := 0
			
			if y < border_up:
				border_thickness_y = border_up - y
			elif y > border_down:
				border_thickness_y = y - border_down
			
			var idx = calc_point_index(x, y)
			
			var h = _buffer[idx]
			h += max(border_thickness_x, border_thickness_y) * (border_thickness * (1 if border_montains else -1))
			_buffer[idx] = h


func generate_places() -> void:
	var offset := int(size / 15)
	var places := []
	
	var first_connection_generated := false
	
	var dir_idx = randi() % 4
	var dir:Vector2 = DIRS[dir_idx]
	var connections := []
	
	for _i in range(DIRS.size()):
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
		
		create_square(x, y, border_connection_size, border_connection_size, true)
		var center = Vector2(int(x + border_connection_size / 2), int(y + border_connection_size / 2))
		places.push_back(center)
	
	for _i in range(places_count):
		var x = randi() % (size - offset * 3) + offset
		var y = randi() % (size - offset * 3) + offset
		var w = randi() % offset * 2 + offset
		var h = randi() % offset * 2 + offset
		
		create_square(x, y, w, h)
		places.push_back(Vector2(int(x + w / 2), int(y + h / 2)))

	if is_connect_places:
		connect_places(places)


func create_square(sx: int, sy: int, swidth: int, sheight: int, connection := false) -> void:
	var rect := Rect2(sx, sy, swidth, sheight)
	var map_rect = Rect2(0, 0, size, size)
	var half_size:Vector2 = (rect.end - rect.position) / 2
	var center := Vector2(rect.position.x + int(half_size.x), rect.position.y + int(half_size.y))
		
	if not map_rect.encloses(rect):
		return
	
	var sborder_thickness := int(float((swidth + sheight) / 2 / 5.0))
	var border_rect = Rect2(rect.position.x - sborder_thickness, 
		rect.position.y - sborder_thickness,  
		rect.end.x + (sborder_thickness * 2) - 1, 
		rect.end.y + (sborder_thickness * 2) - 1)
		
	var connection_rect :Rect2 = map_rect.grow(-border_connection_size/2)
	
	for pixel_x in range(rect.position.x, rect.end.x):
		for pixel_y in range(rect.position.y, rect.end.y):
			var pixel_point = Vector2(pixel_x, pixel_y)
			
			if not map_rect.has_point(pixel_point):
				continue
			
			var h := 0.5 #TODO Find a better way to place this const
			var idx = calc_point_index(pixel_x, pixel_y)
			
			if not connection or connection_rect.has_point(pixel_point):
				h = _buffer[idx]
				var dist :float = (pixel_point - center).length()
				var diff :float = (half_size.length() - dist) / half_size.length()
				var diff_h = h - 0.5
				h -= diff_h * diff 
			
			_buffer[idx] = h

	if is_smooth_connection_border:
		var point := center
		var walk_left := 1
		
		var dir_cnt := 0
		var dir: Vector2 = DIRS[dir_cnt]
		var dir_mod := 0
		
		while border_rect.has_point(point):
			if map_rect.has_point(point) && not rect.has_point(point):
				smooth_pixel(int(point.x), int(point.y))
			
			walk_left -= 1
			
			if walk_left <= 0:
				dir_mod += 1
				dir = DIRS[dir_mod % 4]
				
				dir_cnt += (1 if dir_mod % 2 == 1 else 0)
				walk_left = dir_cnt
			
			point += dir


func smooth_pixel(x: int, y: int) -> void:
	var map_rect = Rect2(0, 0, size, size)
	var h := 0.0
	var count := 0
	
	for i in range (-1, 2):
		for k in range (-1, 2):
			var point = Vector2(x + i, y + k)
			
			if not map_rect.has_point(point):
				continue
			
			var idx := calc_point_index(point.x, point.y)
			h += _buffer[idx]
			count += 1
	
	
	if count > 0 :
		var idx := calc_point_index(x, y)
		_buffer[idx] = h / count

class DistanceSorter:
	var target := Vector2.ZERO
	
	func sort(a, b):
		if (target - a).length() < (target - b).length():
			return true
		else:
			return false

func connect_places(places) -> void:
	while not places.empty():
		var point = places.pop_back();
		
		if places.empty():
			return
		
		var sorter := DistanceSorter.new()
		sorter.target = point
		places.sort_custom(sorter, "sort")
		generate_path(point, places.front())


static func sort_by_distance(a, b) -> bool:
	if a[1] < b[1]:
		return true
	else:
		return false


func generate_path(origin: Vector2, dest: Vector2) -> void:
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
			draw_path(walked)
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


func draw_path(path) -> void:
	var map_rect = Rect2(0, 0, size, size)
	
	for p in path:
		for dir in DIRS:
			for i in range(1, places_path_thickness):
				var pixel = p + (dir * i)
				if map_rect.has_point(pixel):
					var idx = calc_point_index(pixel.x, pixel.y)
					_buffer[idx] = 0.5
	
	for p in path:
		for dir in DIRS:
			for i in range(1, int(places_path_thickness * 2)):
				var pixel = p + (dir * i)
				if map_rect.has_point(pixel):
					smooth_pixel(pixel.x, pixel.y)


func calc_point_index(x: int, y: int) -> int:
	return int(x) * size + int(y)


func calc_distance_length(a: Vector2, b: Vector2) -> float:
	return (a-b).length()


func height_at(x: int, y: int) -> float:
	return _buffer[calc_point_index(x, y)]
