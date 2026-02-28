extends RefCounted


var _lost_time: float = 0.0


func reset() -> void:
	_lost_time = 0.0


func tick(delta: float, out_of_range: bool) -> float:
	if out_of_range:
		_lost_time += max(delta, 0.0)
	else:
		_lost_time = 0.0
	return _lost_time


func is_lost(timeout_seconds: float) -> bool:
	return _lost_time >= max(timeout_seconds, 0.0)
