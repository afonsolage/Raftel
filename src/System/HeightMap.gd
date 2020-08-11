class_name HeightMap

var _buffer := []
var _size := 0

func init(size: int):
	_size = size
	_buffer.resize(size * size)


func set_at(x: int, y: int, value: float) -> void:
	_buffer[calc_index(x ,y)] = value
	

func get_at(x: int, y: int) -> float:
	return _buffer[calc_index(x, y)]

	
func calc_index(x: int, y: int) -> int:
	return x * _size + y
