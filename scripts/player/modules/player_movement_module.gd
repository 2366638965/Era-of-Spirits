extends RefCounted


func move(body: CharacterBody2D, direction: Vector2, move_speed: float) -> void:
	if body == null:
		return

	var normalized_direction := direction
	if normalized_direction != Vector2.ZERO:
		normalized_direction = normalized_direction.normalized()

	body.velocity = normalized_direction * move_speed
	body.move_and_slide()
