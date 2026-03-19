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

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _fx_sprite: Sprite2D = _resolve_fx_sprite()

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
		_movement_module.stop(self)
		_state_module.force_state(EnemyStateModule.State.HIT)
		_play_current_state_animation()
		return

	_target = _resolve_target_if_needed()
	if not _targeting_module.has_valid_target(_target):
		_attack_module.interrupt_attack()
		_movement_module.stop(self)
		_state_module.try_set_state(EnemyStateModule.State.IDLE)
		_play_current_state_animation()
		return

	var distance_to_target_value: float = _targeting_module.distance_to_target(global_position, _target)
	if not _targeting_module.is_in_chase_range(distance_to_target_value, chase_range):
		_attack_module.interrupt_attack()
		_movement_module.stop(self)
		_state_module.try_set_state(EnemyStateModule.State.IDLE)
		_play_current_state_animation()
		return

	if _attack_module.is_attacking():
		_movement_module.stop(self)
		_state_module.force_state(EnemyStateModule.State.ATTACK)
		_play_current_state_animation()
		return

	var in_attack_range: bool = _targeting_module.is_in_attack_range(distance_to_target_value, attack_range)
	if _attack_module.can_start_attack(in_attack_range):
		_start_attack_state()
		return

	var use_run: bool = _targeting_module.should_run(distance_to_target_value, run_range)
	var chase_speed: float = run_speed if use_run else walk_speed
	var move_direction: Vector2 = _movement_module.chase_target(self, _target.global_position, chase_speed)
	_movement_module.update_facing(_animated_sprite, move_direction)
	_state_module.try_set_state(EnemyStateModule.State.RUN if use_run else EnemyStateModule.State.WALK)
	_play_current_state_animation()


func apply_hit(custom_stun_duration: float = -1.0) -> void:
	var stun: float = hit_stun_duration if custom_stun_duration < 0.0 else custom_stun_duration
	_hit_module.enter_hit(stun)
	_attack_module.interrupt_attack()
	_movement_module.stop(self)
	_state_module.force_state(EnemyStateModule.State.HIT)
	_play_current_state_animation()


func _start_attack_state() -> void:
	_attack_module.start_attack(attack_cooldown)
	_movement_module.stop(self)
	_state_module.force_state(EnemyStateModule.State.ATTACK)
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
	var show_fx: bool = _animated_sprite.animation == &"spirit11_attack_1" and _animated_sprite.frame == 2
	_set_fx_visible(show_fx)


func _on_animated_sprite_animation_finished() -> void:
	if _animated_sprite == null:
		return
	if _animated_sprite.animation == &"spirit11_attack_1":
		_attack_module.finish_attack()
		_state_module.try_set_state(EnemyStateModule.State.IDLE)
		_set_fx_visible(false)
		_play_current_state_animation()


func _set_fx_visible(visible_value: bool) -> void:
	if _fx_sprite == null:
		return
	_fx_sprite.visible = visible_value


func _resolve_fx_sprite() -> Sprite2D:
	var by_fx_name: Sprite2D = get_node_or_null("FxSprite") as Sprite2D
	if by_fx_name != null:
		return by_fx_name
	return get_node_or_null("FxSlash") as Sprite2D
