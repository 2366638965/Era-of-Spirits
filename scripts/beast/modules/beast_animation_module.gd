extends RefCounted


var _animated_sprite: AnimatedSprite2D


func _init(animated_sprite: AnimatedSprite2D) -> void:
	_animated_sprite = animated_sprite


func update(direction: Vector2) -> void:
	if _animated_sprite == null:
		return

	if direction.length_squared() <= 0.0001:
		_play_idle()
		return

	_play_run(direction)


func _play_run(direction: Vector2) -> void:
	var horizontal_priority := absf(direction.x) > absf(direction.y)
	if horizontal_priority:
		_animated_sprite.flip_h = direction.x < 0.0
		_animated_sprite.play(&"run_right")
		return

	_animated_sprite.flip_h = false
	if direction.y < 0.0:
		_animated_sprite.play(&"run_up")
	else:
		_animated_sprite.play(&"run_down")


func _play_idle() -> void:
	var current := _animated_sprite.animation
	match current:
		&"run_up":
			_animated_sprite.flip_h = false
			_animated_sprite.play(&"idle_up")
		&"run_down":
			_animated_sprite.flip_h = false
			_animated_sprite.play(&"idle_down")
		_:
			_animated_sprite.play(&"idle_right")
