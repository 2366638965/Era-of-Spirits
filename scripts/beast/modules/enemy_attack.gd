extends RefCounted
# Function Description:
# Controls attack start conditions and cooldown timing, ready for combo expansion.


var _cooldown_left: float = 0.0
var _is_attacking: bool = false


func tick(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - maxf(delta, 0.0), 0.0)


func can_start_attack(in_attack_range: bool) -> bool:
	return in_attack_range and not _is_attacking and _cooldown_left <= 0.0


func start_attack(attack_cooldown: float) -> void:
	_is_attacking = true
	_cooldown_left = maxf(attack_cooldown, 0.0)


func interrupt_attack() -> void:
	_is_attacking = false


func finish_attack() -> void:
	_is_attacking = false


func is_attacking() -> bool:
	return _is_attacking
