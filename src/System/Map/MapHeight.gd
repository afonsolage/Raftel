class_name MapHeight

var _buffer := []
var _size := 0

func init(size: int):
	_size = size
	_buffer.resize(size * size)
	for i in size * size:
		_buffer[i] = 0


func set_at(x: int, y: int, value: float) -> void:
	_buffer[calc_index(x ,y)] = value
	

func get_at(x: int, y: int) -> float:
	return _buffer[calc_index(x, y)]

	
func calc_index(x: int, y: int) -> int:
	return x * _size + y
