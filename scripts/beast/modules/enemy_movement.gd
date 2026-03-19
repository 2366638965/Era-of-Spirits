extends RefCounted
# Function Description:
# Handles chase movement and facing updates from target position + speed.


func chase_target(
	body: CharacterBody2D,
	target_position: Vector2,
	speed: float
) -> Vector2:
	if body == null:
		return Vector2.ZERO

	var direction: Vector2 = target_position - body.global_position
	if direction == Vector2.ZERO:
		body.velocity = Vector2.ZERO
		body.move_and_slide()
		return Vector2.ZERO

	direction = direction.normalized()
	body.velocity = direction * maxf(speed, 0.0)
	body.move_and_slide()
	return direction


func stop(body: CharacterBody2D) -> void:
	if body == null:
		return
	body.velocity = Vector2.ZERO
	body.move_and_slide()


func update_facing(animated_sprite: AnimatedSprite2D, direction: Vector2) -> void:
	if animated_sprite == null:
		return
	if direction.x < 0.0:
		animated_sprite.flip_h = true
	elif direction.x > 0.0:
		animated_sprite.flip_h = false
