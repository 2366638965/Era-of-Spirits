extends RefCounted


const ANIM_ATTACK := &"attack_boxing_right"
const ANIM_IDLE := &"idle_right"
const ANIM_JUMP := &"jump_right"
const ANIM_RUN := &"run_right"
const ANIM_WALK := &"walk_right"


func update_animation(
	animated_sprite: AnimatedSprite2D,
	facing_left: bool,
	is_attacking: bool,
	is_jumping: bool,
	direction: Vector2,
	should_run: bool
) -> void:
	if animated_sprite == null:
		return

	animated_sprite.flip_h = facing_left

	if is_attacking:
		_play_anim(animated_sprite, ANIM_ATTACK)
		return

	if is_jumping:
		_play_anim(animated_sprite, ANIM_JUMP)
		return

	if direction == Vector2.ZERO:
		_play_anim(animated_sprite, ANIM_IDLE)
		return

	if should_run:
		_play_anim(animated_sprite, ANIM_RUN)
	else:
		_play_anim(animated_sprite, ANIM_WALK)


func play_idle(animated_sprite: AnimatedSprite2D) -> void:
	_play_anim(animated_sprite, ANIM_IDLE)


func _play_anim(animated_sprite: AnimatedSprite2D, anim_name: StringName) -> void:
	if animated_sprite == null:
		return
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()
