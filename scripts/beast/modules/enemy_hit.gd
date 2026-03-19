extends RefCounted
# Function Description:
# Manages hit-stun timing and interruption, then returns control to normal AI flow.


var _is_in_hit_stun: bool = false
var _stun_left: float = 0.0


func tick(delta: float) -> bool:
	if not _is_in_hit_stun:
		return false
	_stun_left = maxf(_stun_left - maxf(delta, 0.0), 0.0)
	if _stun_left <= 0.0:
		_is_in_hit_stun = false
		return true
	return false


func enter_hit(hit_stun_duration: float) -> void:
	_is_in_hit_stun = true
	_stun_left = maxf(hit_stun_duration, 0.0)


func cancel_hit() -> void:
	_is_in_hit_stun = false
	_stun_left = 0.0


func is_in_hit_stun() -> bool:
	return _is_in_hit_stun
