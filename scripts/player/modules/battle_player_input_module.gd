extends RefCounted


const ACTION_LEFT := &"left"
const ACTION_RIGHT := &"right"
const ACTION_UP := &"up"
const ACTION_DOWN := &"down"
const ACTION_WALK_LEFT := &"walk_left"
const ACTION_WALK_RIGHT := &"walk_right"
const ACTION_WALK_UP := &"walk_up"
const ACTION_WALK_DOWN := &"walk_down"

enum MoveSource {
	NONE,
	NORMAL,
	WALK
}


func resolve_priority_move_input(
	delta: float,
	normal_hold_time: float,
	normal_run_hold_seconds: float,
	run_modifier_actions: PackedStringArray
) -> Dictionary:
	var normal_direction: Vector2 = _vector_from_actions(ACTION_LEFT, ACTION_RIGHT, ACTION_UP, ACTION_DOWN)
	var walk_direction: Vector2 = _vector_from_actions(ACTION_WALK_LEFT, ACTION_WALK_RIGHT, ACTION_WALK_UP, ACTION_WALK_DOWN)

	var source: int = MoveSource.NONE
	var direction: Vector2 = Vector2.ZERO

	if normal_direction != Vector2.ZERO:
		source = MoveSource.NORMAL
		direction = normal_direction
	elif walk_direction != Vector2.ZERO:
		source = MoveSource.WALK
		direction = walk_direction

	if source == MoveSource.NORMAL:
		normal_hold_time += delta
	else:
		normal_hold_time = 0.0

	var run_modifier_pressed: bool = _is_run_modifier_pressed(run_modifier_actions)
	var should_run: bool = false

	if source == MoveSource.NORMAL:
		should_run = run_modifier_pressed or normal_hold_time >= normal_run_hold_seconds
	elif source == MoveSource.WALK:
		should_run = run_modifier_pressed

	return {
		"direction": direction,
		"source": source,
		"run": should_run,
		"normal_hold_time": normal_hold_time
	}


func _vector_from_actions(left_action: StringName, right_action: StringName, up_action: StringName, down_action: StringName) -> Vector2:
	var x: float = _action_strength(right_action) - _action_strength(left_action)
	var y: float = _action_strength(down_action) - _action_strength(up_action)
	return Vector2(x, y)


func _action_strength(action_name: StringName) -> float:
	if not InputMap.has_action(action_name):
		return 0.0
	return Input.get_action_strength(action_name)


func _is_run_modifier_pressed(run_modifier_actions: PackedStringArray) -> bool:
	for action_name in run_modifier_actions:
		if InputMap.has_action(action_name) and Input.is_action_pressed(action_name):
			return true
	return false
