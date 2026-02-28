extends RefCounted


func get_move_direction() -> Vector2:
	var direction := _vector_from_actions("left", "right", "up", "down")
	if direction == Vector2.ZERO:
		direction = _vector_from_actions("walk_left", "walk_right", "walk_up", "walk_down")
	if direction == Vector2.ZERO:
		direction = _vector_from_actions("ui_left", "ui_right", "ui_up", "ui_down")
	return direction


func _vector_from_actions(left_action: StringName, right_action: StringName, up_action: StringName, down_action: StringName) -> Vector2:
	var x := Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
	var y := Input.get_action_strength(down_action) - Input.get_action_strength(up_action)
	return Vector2(x, y)
