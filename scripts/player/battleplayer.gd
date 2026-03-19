extends CharacterBody2D


@export var walk_speed: float = 180.0
@export var run_speed: float = 320.0
@export var normal_run_hold_seconds: float = 2.0
@export var jump_duration: float = 0.95
@export var jump_peak_height: float = 165.0
@export var jump_forward_speed_walk: float = 220.0
@export var jump_forward_speed_run: float = 300.0
@export var attack_duration: float = 0.45
@export var run_modifier_actions: PackedStringArray = PackedStringArray(["run_modifier", "run", "sprint", "switch_control"])
@export var edge_rebound_enabled: bool = true
@export var edge_rebound_speed: float = 120.0
@export var edge_rebound_duration: float = 0.08
@export var edge_rebound_cooldown: float = 0.12

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D
@onready var _sensor_area: Area2D = $Area2D
@onready var _body_collision_shape: CollisionShape2D = $CollisionShape2D

const BattlePlayerInputModule = preload("res://scripts/player/modules/battle_player_input_module.gd")
const BattlePlayerAnimationModule = preload("res://scripts/player/modules/battle_player_animation_module.gd")
const BattlePlayerBoundsModule = preload("res://scripts/player/modules/battle_player_bounds_module.gd")

const ACTION_ATTACK := &"attack"
const ACTION_JUMP := &"jump"

var _facing_left: bool = false
var _normal_hold_time: float = 0.0
var _is_jumping: bool = false
var _is_attacking: bool = false
var _jump_time_left: float = 0.0
var _jump_elapsed_time: float = 0.0
var _jump_move_velocity: Vector2 = Vector2.ZERO
var _attack_time_left: float = 0.0
var _attack_chain_requested: bool = false
var _sprite_ground_position: Vector2 = Vector2.ZERO

var _middle_wall_area: Area2D
var _middle_wall_shape: CollisionShape2D
var _wall_area: Area2D
var _right_wall_shape: CollisionShape2D
var _left_wall_shape: CollisionShape2D
var _top_wall_shape: CollisionShape2D
var _bottom_wall_shape: CollisionShape2D

var _has_wall_limits: bool = false
var _wall_left_limit: float = -INF
var _wall_right_limit: float = INF
var _wall_top_limit: float = -INF
var _wall_bottom_limit: float = INF
var _edge_rebound_velocity: Vector2 = Vector2.ZERO
var _edge_rebound_time_left: float = 0.0
var _edge_rebound_cooldown_left: float = 0.0

var _input_module: RefCounted
var _animation_module: RefCounted
var _bounds_module: RefCounted


func _ready() -> void:
	add_to_group("player")
	_input_module = BattlePlayerInputModule.new()
	_animation_module = BattlePlayerAnimationModule.new()
	_bounds_module = BattlePlayerBoundsModule.new()

	if _camera != null:
		_camera.make_current()
	if _animated_sprite != null:
		_sprite_ground_position = _animated_sprite.position

	_resolve_battle_nodes()
	_refresh_wall_limits()
	_configure_camera_limits()
	_animation_module.play_idle(_animated_sprite)


func _physics_process(delta: float) -> void:
	_tick_action_timers(delta)

	var move_input: Dictionary = _resolve_priority_move_input(delta)
	_normal_hold_time = float(move_input.get("normal_hold_time", _normal_hold_time))
	var input_direction: Vector2 = move_input.get("direction", Vector2.ZERO)
	var input_should_run: bool = bool(move_input.get("run", false))

	_handle_jump_input(input_direction, input_should_run)
	_handle_attack_input()

	var direction: Vector2 = input_direction
	var should_run: bool = input_should_run

	if _is_jumping and _jump_move_velocity != Vector2.ZERO:
		direction = _jump_move_velocity.normalized()

	if _is_jumping:
		should_run = false
		if _jump_move_velocity == Vector2.ZERO:
			direction = Vector2.ZERO
	else:
		_jump_move_velocity = Vector2.ZERO

	if direction.x < 0.0:
		_facing_left = true
	elif direction.x > 0.0:
		_facing_left = false

	direction = _apply_middle_wall_block(direction)

	if _is_attacking and not _is_jumping:
		direction = Vector2.ZERO
		should_run = false
		_edge_rebound_velocity = Vector2.ZERO
		_edge_rebound_time_left = 0.0

	if _is_jumping:
		velocity = _jump_move_velocity
	elif _is_attacking:
		velocity = Vector2.ZERO
	elif direction != Vector2.ZERO:
		direction = direction.normalized()
		var speed: float = run_speed if should_run else walk_speed
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	var wall_hit_state: Dictionary = _clamp_player_inside_wall_bounds()
	_handle_edge_rebound(direction, wall_hit_state, delta)
	_update_animation(direction, should_run)


func _exit_tree() -> void:
	_set_middle_wall_collision_enabled(true)


func _resolve_priority_move_input(delta: float) -> Dictionary:
	return _input_module.resolve_priority_move_input(
		delta,
		_normal_hold_time,
		normal_run_hold_seconds,
		run_modifier_actions
	)


func _tick_action_timers(delta: float) -> void:
	if _is_attacking:
		_attack_time_left -= delta
		if _attack_time_left <= 0.0:
			if _attack_chain_requested or (InputMap.has_action(ACTION_ATTACK) and Input.is_action_pressed(ACTION_ATTACK)):
				_start_attack()
			else:
				_is_attacking = false
				_attack_time_left = 0.0
				_attack_chain_requested = false

	if _is_jumping:
		_jump_elapsed_time += delta
		_update_jump_arc_visual()
		_jump_time_left -= delta
		if _jump_time_left <= 0.0:
			_stop_jump()


func _can_start_jump() -> bool:
	if _is_jumping:
		return false
	if _is_attacking:
		return false
	if not InputMap.has_action(ACTION_JUMP):
		return false
	return Input.is_action_just_pressed(ACTION_JUMP)


func _start_attack() -> void:
	_is_attacking = true
	_attack_time_left = maxf(attack_duration, 0.05)
	_attack_chain_requested = false


func _handle_attack_input() -> void:
	if _is_jumping:
		_attack_chain_requested = false
		return
	if not InputMap.has_action(ACTION_ATTACK):
		return

	if Input.is_action_just_pressed(ACTION_ATTACK):
		if _is_attacking:
			_attack_chain_requested = true
		else:
			_start_attack()
	elif _is_attacking and Input.is_action_pressed(ACTION_ATTACK):
		_attack_chain_requested = true


func _handle_jump_input(input_direction: Vector2, input_should_run: bool) -> void:
	if _can_start_jump():
		_start_jump(input_direction, input_should_run)


func _start_jump(input_direction: Vector2, input_should_run: bool) -> void:
	_is_jumping = true
	_jump_time_left = maxf(jump_duration, 0.05)
	_jump_elapsed_time = 0.0
	_jump_move_velocity = Vector2.ZERO
	if input_direction != Vector2.ZERO:
		var jump_speed: float = jump_forward_speed_run if input_should_run else jump_forward_speed_walk
		_jump_move_velocity = input_direction.normalized() * jump_speed
	_attack_chain_requested = false
	_edge_rebound_velocity = Vector2.ZERO
	_edge_rebound_time_left = 0.0
	_update_jump_arc_visual()
	_set_middle_wall_collision_enabled(false)


func _stop_jump() -> void:
	_is_jumping = false
	_jump_time_left = 0.0
	_jump_elapsed_time = 0.0
	_jump_move_velocity = Vector2.ZERO
	if _animated_sprite != null:
		_animated_sprite.position = _sprite_ground_position
	_set_middle_wall_collision_enabled(true)


func _update_jump_arc_visual() -> void:
	if _animated_sprite == null:
		return
	var duration: float = maxf(jump_duration, 0.05)
	var t: float = clampf(_jump_elapsed_time / duration, 0.0, 1.0)
	var normalized_phase: float = (2.0 * t) - 1.0
	var curve: float = 1.0 - (normalized_phase * normalized_phase)
	var height: float = jump_peak_height * curve
	_animated_sprite.position = _sprite_ground_position + Vector2(0.0, -height)


func _update_animation(direction: Vector2, should_run: bool) -> void:
	_animation_module.update_animation(
		_animated_sprite,
		_facing_left,
		_is_attacking,
		_is_jumping,
		direction,
		should_run
	)


func _resolve_battle_nodes() -> void:
	var nodes: Dictionary = _bounds_module.resolve_battle_nodes(get_parent())
	_middle_wall_area = nodes.get("middle_wall_area", null) as Area2D
	_middle_wall_shape = nodes.get("middle_wall_shape", null) as CollisionShape2D
	_wall_area = nodes.get("wall_area", null) as Area2D
	_right_wall_shape = nodes.get("right_wall_shape", null) as CollisionShape2D
	_left_wall_shape = nodes.get("left_wall_shape", null) as CollisionShape2D
	_top_wall_shape = nodes.get("top_wall_shape", null) as CollisionShape2D
	_bottom_wall_shape = nodes.get("bottom_wall_shape", null) as CollisionShape2D


func _refresh_wall_limits() -> void:
	var limits: Dictionary = _bounds_module.refresh_wall_limits(
		_right_wall_shape,
		_left_wall_shape,
		_top_wall_shape,
		_bottom_wall_shape
	)
	_has_wall_limits = bool(limits.get("has_limits", false))
	_wall_left_limit = float(limits.get("left", -INF))
	_wall_right_limit = float(limits.get("right", INF))
	_wall_top_limit = float(limits.get("top", -INF))
	_wall_bottom_limit = float(limits.get("bottom", INF))


func _configure_camera_limits() -> void:
	_bounds_module.configure_camera_limits(
		_camera,
		_has_wall_limits,
		_wall_left_limit,
		_wall_right_limit,
		_wall_top_limit,
		_wall_bottom_limit
	)


func _clamp_player_inside_wall_bounds() -> Dictionary:
	var default_hit_state: Dictionary = {
		"left": false,
		"right": false,
		"top": false,
		"bottom": false
	}
	var result: Dictionary = _bounds_module.clamp_player_inside_wall_bounds(
		global_position,
		_body_collision_shape,
		_has_wall_limits,
		_wall_left_limit,
		_wall_right_limit,
		_wall_top_limit,
		_wall_bottom_limit
	)
	global_position = result.get("position", global_position)
	return result.get("hit_state", default_hit_state)


func _handle_edge_rebound(direction: Vector2, wall_hit_state: Dictionary, delta: float) -> void:
	if _edge_rebound_cooldown_left > 0.0:
		_edge_rebound_cooldown_left -= delta

	if _edge_rebound_time_left > 0.0:
		global_position += _edge_rebound_velocity * delta
		_edge_rebound_time_left -= delta
		if _edge_rebound_time_left <= 0.0:
			_edge_rebound_time_left = 0.0
			_edge_rebound_velocity = Vector2.ZERO
		_clamp_player_inside_wall_bounds()

	if not edge_rebound_enabled:
		return
	if _is_attacking and not _is_jumping:
		return
	if _edge_rebound_cooldown_left > 0.0:
		return
	if direction == Vector2.ZERO:
		return

	var rebound_dir: Vector2 = Vector2.ZERO
	if wall_hit_state["left"] and direction.x < 0.0:
		rebound_dir.x = 1.0
	elif wall_hit_state["right"] and direction.x > 0.0:
		rebound_dir.x = -1.0

	if wall_hit_state["top"] and direction.y < 0.0:
		rebound_dir.y = 1.0
	elif wall_hit_state["bottom"] and direction.y > 0.0:
		rebound_dir.y = -1.0

	if rebound_dir == Vector2.ZERO:
		return

	_edge_rebound_velocity = rebound_dir.normalized() * edge_rebound_speed
	_edge_rebound_time_left = maxf(edge_rebound_duration, 0.01)
	_edge_rebound_cooldown_left = maxf(edge_rebound_cooldown, 0.01)


func _apply_middle_wall_block(direction: Vector2) -> Vector2:
	return _bounds_module.apply_middle_wall_block(
		direction,
		_is_jumping,
		_middle_wall_area,
		_sensor_area,
		global_position
	)


func _set_middle_wall_collision_enabled(enabled: bool) -> void:
	if _middle_wall_shape == null:
		return
	_middle_wall_shape.disabled = not enabled
