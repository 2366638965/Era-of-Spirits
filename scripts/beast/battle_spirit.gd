extends CharacterBody2D
# Function Description:
# Enemy main controller. Owns parameters, modules, state orchestration,
# animation presentation, and attack FX frame checks.


@export_group("Battle Params")
@export var walk_speed: float = 90.0
@export var run_speed: float = 150.0
@export var chase_range: float = 700.0
@export var run_range: float = 260.0
@export var attack_range: float = 120.0
@export var attack_cooldown: float = 0.9
@export var hit_stun_duration: float = 0.28
@export var player_node_path: NodePath
@export var fx_offset_x: float = 93.0
@export var fx_offset_y: float = 28.0
@export var attack_area_offset_x: float = 92.0
@export var attack_area_offset_y: float = 16.0

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _fx_sprite: Sprite2D = _resolve_fx_sprite()
@onready var _hurt_area: Area2D = $Area2D
@onready var _attack_area: Area2D = $AttackArea2D

const EnemyStateModule = preload("res://scripts/beast/modules/enemy_state.gd")
const EnemyTargetingModule = preload("res://scripts/beast/modules/enemy_targeting.gd")
const EnemyMovementModule = preload("res://scripts/beast/modules/enemy_movement.gd")
const EnemyAttackModule = preload("res://scripts/beast/modules/enemy_attack.gd")
const EnemyHitModule = preload("res://scripts/beast/modules/enemy_hit.gd")

var _state_module
var _targeting_module
var _movement_module
var _attack_module
var _hit_module

var _target: CharacterBody2D
var _received_attack_by_attacker: Dictionary = {}
var _attack_sequence: int = 0


func _ready() -> void:
	_state_module = EnemyStateModule.new()
	_targeting_module = EnemyTargetingModule.new()
	_movement_module = EnemyMovementModule.new()
	_attack_module = EnemyAttackModule.new()
	_hit_module = EnemyHitModule.new()

	if _animated_sprite != null:
		if not _animated_sprite.frame_changed.is_connected(_on_animated_sprite_frame_changed):
			_animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)
		if not _animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
			_animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	if _hurt_area != null:
		_hurt_area.monitoring = true
		_hurt_area.monitorable = true

	_set_attack_area_active(false)
	_sync_fx_transform()
	_set_fx_visible(false)
	_state_module.force_state(EnemyStateModule.State.IDLE)
	_play_current_state_animation()


func _physics_process(delta: float) -> void:
	_attack_module.tick(delta)

	var hit_ended: bool = _hit_module.tick(delta)
	if hit_ended:
		_state_module.try_set_state(EnemyStateModule.State.IDLE)

	if _hit_module.is_in_hit_stun():
		_attack_module.interrupt_attack()
		_set_attack_area_active(false)
		_movement_module.stop(self)
		_state_module.force_state(EnemyStateModule.State.HIT)
		_sync_fx_transform()
		_play_current_state_animation()
		return

	if _try_receive_player_attack():
		_sync_fx_transform()
		return

	_target = _resolve_target_if_needed()
	if not _targeting_module.has_valid_target(_target):
		_attack_module.interrupt_attack()
		_set_attack_area_active(false)
		_movement_module.stop(self)
		_state_module.try_set_state(EnemyStateModule.State.IDLE)
		_sync_fx_transform()
		_play_current_state_animation()
		return

	var distance_to_target_value: float = _targeting_module.distance_to_target(global_position, _target)
	if not _targeting_module.is_in_chase_range(distance_to_target_value, chase_range):
		_attack_module.interrupt_attack()
		_set_attack_area_active(false)
		_movement_module.stop(self)
		_state_module.try_set_state(EnemyStateModule.State.IDLE)
		_sync_fx_transform()
		_play_current_state_animation()
		return

	if _attack_module.is_attacking():
		_movement_module.stop(self)
		_state_module.force_state(EnemyStateModule.State.ATTACK)
		_set_attack_area_active(true)
		_sync_fx_transform()
		_play_current_state_animation()
		return

	var in_attack_range: bool = _targeting_module.is_in_attack_range(distance_to_target_value, attack_range)
	if _attack_module.can_start_attack(in_attack_range):
		_start_attack_state()
		return

	_set_attack_area_active(false)
	var use_run: bool = _targeting_module.should_run(distance_to_target_value, run_range)
	var chase_speed: float = run_speed if use_run else walk_speed
	var move_direction: Vector2 = _movement_module.chase_target(self, _target.global_position, chase_speed)
	_movement_module.update_facing(_animated_sprite, move_direction)
	_sync_fx_transform()
	_state_module.try_set_state(EnemyStateModule.State.RUN if use_run else EnemyStateModule.State.WALK)
	_play_current_state_animation()


func apply_hit(custom_stun_duration: float = -1.0) -> void:
	var stun: float = hit_stun_duration if custom_stun_duration < 0.0 else custom_stun_duration
	_hit_module.enter_hit(stun)
	_attack_module.interrupt_attack()
	_set_attack_area_active(false)
	_movement_module.stop(self)
	_state_module.force_state(EnemyStateModule.State.HIT)
	_sync_fx_transform()
	_play_current_state_animation()


func _start_attack_state() -> void:
	_attack_module.start_attack(attack_cooldown)
	_attack_sequence += 1
	_set_attack_area_active(true)
	_movement_module.stop(self)
	_state_module.force_state(EnemyStateModule.State.ATTACK)
	_sync_fx_transform()
	_play_current_state_animation()


func _play_current_state_animation() -> void:
	if _animated_sprite == null:
		return
	var anim_name: StringName = _state_module.get_anim_name()
	if _animated_sprite.animation != anim_name:
		_animated_sprite.play(anim_name)
	elif not _animated_sprite.is_playing():
		_animated_sprite.play()


func _resolve_target_if_needed() -> CharacterBody2D:
	if _targeting_module.has_valid_target(_target):
		return _target
	return _targeting_module.resolve_player(self, player_node_path)


func _on_animated_sprite_frame_changed() -> void:
	if _animated_sprite == null:
		return
	_sync_fx_transform()
	var show_fx: bool = _animated_sprite.animation == &"spirit11_attack_1" and _animated_sprite.frame == 2
	_set_fx_visible(show_fx)


func _on_animated_sprite_animation_finished() -> void:
	if _animated_sprite == null:
		return
	if _animated_sprite.animation == &"spirit11_attack_1":
		_attack_module.finish_attack()
		_set_attack_area_active(false)
		_state_module.try_set_state(EnemyStateModule.State.IDLE)
		_set_fx_visible(false)
		_play_current_state_animation()


func _set_fx_visible(visible_value: bool) -> void:
	if _fx_sprite == null:
		return
	_fx_sprite.visible = visible_value


func _sync_fx_transform() -> void:
	if _fx_sprite == null or _animated_sprite == null:
		return

	var x_offset_abs: float = absf(fx_offset_x)
	var sprite_is_flipped: bool = _animated_sprite.flip_h
	_fx_sprite.flip_h = sprite_is_flipped
	# Keep default side on negative X, and mirror to positive X when sprite flips.
	_fx_sprite.position.x = x_offset_abs if sprite_is_flipped else -x_offset_abs
	_fx_sprite.position.y = fx_offset_y
	_sync_attack_area_transform()


func _try_receive_player_attack() -> bool:
	if _hurt_area == null:
		return false

	var overlapping_areas: Array[Area2D] = _hurt_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area == null:
			continue
		var attacker := area.get_parent()
		if not (attacker is CharacterBody2D):
			continue
		if not attacker.is_in_group("player"):
			continue
		if not attacker.has_method("is_attack_active"):
			continue
		if not bool(attacker.call("is_attack_active")):
			continue
		if not attacker.has_method("get_attack_sequence"):
			continue

		var attacker_id: int = attacker.get_instance_id()
		var attack_seq: int = int(attacker.call("get_attack_sequence"))
		var last_seq: int = int(_received_attack_by_attacker.get(attacker_id, -1))
		if attack_seq <= last_seq:
			continue

		_received_attack_by_attacker[attacker_id] = attack_seq
		apply_hit()
		return true

	return false


func _set_attack_area_active(active: bool) -> void:
	if _attack_area == null:
		return
	_attack_area.visible = active
	_attack_area.monitoring = active
	_attack_area.monitorable = active


func _sync_attack_area_transform() -> void:
	if _attack_area == null or _animated_sprite == null:
		return
	var x_offset_abs: float = absf(attack_area_offset_x)
	var sprite_is_flipped: bool = _animated_sprite.flip_h
	_attack_area.position.x = x_offset_abs if sprite_is_flipped else -x_offset_abs
	_attack_area.position.y = attack_area_offset_y


func _resolve_fx_sprite() -> Sprite2D:
	var by_fx_name: Sprite2D = get_node_or_null("FxSprite") as Sprite2D
	if by_fx_name != null:
		return by_fx_name
	return get_node_or_null("FxSlash") as Sprite2D


func is_attack_active() -> bool:
	return _attack_module != null and _attack_module.is_attacking()


func get_attack_sequence() -> int:
	return _attack_sequence


func get_attack_area() -> Area2D:
	return _attack_area
