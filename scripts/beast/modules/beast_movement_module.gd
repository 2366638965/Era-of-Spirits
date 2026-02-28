extends RefCounted


func move_towards(body: CharacterBody2D, target_global_position: Vector2, speed: float, arrive_distance: float = 4.0) -> Vector2:
	if body == null:
		return Vector2.ZERO

	var offset := target_global_position - body.global_position
	if offset.length() <= max(arrive_distance, 0.1):
		stop(body)
		return Vector2.ZERO

	var direction := offset.normalized()
	body.velocity = direction * max(speed, 0.0)
	body.move_and_slide()
	return direction


func stop(body: CharacterBody2D) -> void:
	if body == null:
		return

	body.velocity = Vector2.ZERO
	body.move_and_slide()
