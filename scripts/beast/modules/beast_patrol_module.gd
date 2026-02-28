extends RefCounted


var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func next_patrol_point(center: Vector2, radius: float) -> Vector2:
	var valid_radius: float = maxf(radius, 0.0)
	var angle: float = _rng.randf_range(0.0, TAU)
	var distance: float = valid_radius * sqrt(_rng.randf())
	return center + Vector2.RIGHT.rotated(angle) * distance


func next_pause_duration(min_pause: float, max_pause: float) -> float:
	var low: float = minf(min_pause, max_pause)
	var high: float = maxf(min_pause, max_pause)
	if is_equal_approx(low, high):
		return maxf(low, 0.0)
	return maxf(_rng.randf_range(low, high), 0.0)
