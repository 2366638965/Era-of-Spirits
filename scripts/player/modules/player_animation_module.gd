extends RefCounted


var animated_sprite: AnimatedSprite2D
var last_direction: Vector2 = Vector2.DOWN


func _init(sprite: AnimatedSprite2D) -> void:
	animated_sprite = sprite


func update(direction: Vector2, is_running: bool) -> void:
	if animated_sprite == null:
		return

	if direction != Vector2.ZERO:
		last_direction = direction
		if is_running:
			_play_run(direction)
		else:
			_play_walk(direction)
	else:
		_play_idle(last_direction)


func _play_run(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.flip_h = direction.x > 0.0
		animated_sprite.play("run_left")
		return

	animated_sprite.flip_h = false
	if direction.y < 0.0:
		animated_sprite.play("run_up")
	else:
		animated_sprite.play("run_down")


func _play_walk(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.flip_h = direction.x > 0.0
		animated_sprite.play("walk_left")
		return

	animated_sprite.flip_h = false
	if direction.y < 0.0:
		animated_sprite.play("walk_up")
	else:
		animated_sprite.play("walk_down")


func _play_idle(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.flip_h = direction.x > 0.0
		animated_sprite.play("idle_left")
		return

	animated_sprite.flip_h = false
	if direction.y < 0.0:
		animated_sprite.play("idle_up")
	else:
		animated_sprite.play("idle_down")
