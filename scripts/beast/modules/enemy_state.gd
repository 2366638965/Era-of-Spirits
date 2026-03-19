extends RefCounted
# Function Description:
# Defines enemy states and transition rules, centralizing state changes.


enum State {
	IDLE,
	WALK,
	RUN,
	ATTACK,
	HIT
}

const ANIM_BY_STATE := {
	State.IDLE: &"idle",
	State.WALK: &"walk",
	State.RUN: &"run",
	State.ATTACK: &"spirit11_attack_1",
	State.HIT: &"hit"
}

var _current_state: int = State.IDLE


func get_state() -> int:
	return _current_state


func get_anim_name() -> StringName:
	return ANIM_BY_STATE.get(_current_state, &"idle")


func force_state(new_state: int) -> bool:
	if _current_state == new_state:
		return false
	_current_state = new_state
	return true


func try_set_state(new_state: int) -> bool:
	if new_state == _current_state:
		return false
	if not can_transition(_current_state, new_state):
		return false
	_current_state = new_state
	return true


func can_transition(from_state: int, to_state: int) -> bool:
	if from_state == to_state:
		return false
	# Hit has highest priority and can always interrupt.
	if to_state == State.HIT:
		return true
	# While in hit state, only allow transitions out of hit.
	if from_state == State.HIT:
		return to_state != State.HIT
	return true


func is_hit_state() -> bool:
	return _current_state == State.HIT


func is_attack_state() -> bool:
	return _current_state == State.ATTACK
