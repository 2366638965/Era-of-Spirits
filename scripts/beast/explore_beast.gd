extends CharacterBody2D


enum BeastState {
	PATROL_MOVE,
	PATROL_PAUSE,
	CHASE,
}


@export_group("基础")
@export var beast_id: StringName = &"wild_beast"
@export var player_node_path: NodePath
@export var battle_scene_path: String = "res://scenes/battle/grassland01.tscn"
@export var battle_cooldown_seconds: float = 1.0

@export_group("巡逻")
@export var patrol_radius: float = 80.0
@export var patrol_speed: float = 50.0
@export var patrol_arrive_distance: float = 4.0
@export var patrol_pause_min: float = 0.7
@export var patrol_pause_max: float = 1.6

@export_group("追击")
@export var chase_speed: float = 90.0
@export var detect_radius: float = 120.0
@export var lose_target_radius: float = 170.0
@export var lose_target_seconds: float = 3.0


const BeastMovementModule = preload("res://scripts/beast/modules/beast_movement_module.gd")
const BeastPatrolModule = preload("res://scripts/beast/modules/beast_patrol_module.gd")
const BeastAnimationModule = preload("res://scripts/beast/modules/beast_animation_module.gd")
const BeastBattleModule = preload("res://scripts/beast/modules/beast_battle_module.gd")
const BeastChaseModule = preload("res://scripts/beast/modules/beast_chase_module.gd")


@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _battle_area: Area2D = $Area2D


var _movement_module
var _patrol_module
var _animation_module
var _battle_module
var _chase_module

var _state: BeastState = BeastState.PATROL_MOVE
var _spawn_position: Vector2
var _patrol_target: Vector2
var _pause_left: float = 0.0
var _player: CharacterBody2D


func _ready() -> void:
	_spawn_position = global_position

	_movement_module = BeastMovementModule.new()
	_patrol_module = BeastPatrolModule.new()
	_animation_module = BeastAnimationModule.new(_animated_sprite)
	_battle_module = BeastBattleModule.new(battle_cooldown_seconds)
	_chase_module = BeastChaseModule.new()

	_pick_next_patrol_target()
	_player = _resolve_player()

	if _battle_area != null and not _battle_area.body_entered.is_connected(_on_battle_area_body_entered):
		_battle_area.body_entered.connect(_on_battle_area_body_entered)


func _physics_process(delta: float) -> void:
	_battle_module.tick(delta)

	if not is_instance_valid(_player):
		_player = _resolve_player()

	if _state == BeastState.CHASE:
		_tick_chase(delta)
	else:
		_try_enter_chase_state()
		if _state != BeastState.CHASE:
			_tick_patrol(delta)

	_animation_module.update(_direction_from_velocity())


func _tick_patrol(delta: float) -> void:
	if _state == BeastState.PATROL_PAUSE:
		_pause_left = maxf(_pause_left - maxf(delta, 0.0), 0.0)
		_movement_module.stop(self)
		if _pause_left <= 0.0:
			_state = BeastState.PATROL_MOVE
			_pick_next_patrol_target()
		return

	var move_dir: Vector2 = _movement_module.move_towards(
		self,
		_patrol_target,
		patrol_speed,
		patrol_arrive_distance
	)
	if move_dir == Vector2.ZERO:
		_state = BeastState.PATROL_PAUSE
		_pause_left = _patrol_module.next_pause_duration(patrol_pause_min, patrol_pause_max)


func _tick_chase(delta: float) -> void:
	if not is_instance_valid(_player):
		_end_chase_back_to_home()
		return

	var distance_to_player := global_position.distance_to(_player.global_position)
	var out_of_range: bool = distance_to_player > maxf(lose_target_radius, detect_radius)
	_chase_module.tick(delta, out_of_range)

	if _chase_module.is_lost(lose_target_seconds):
		_end_chase_back_to_home()
		return

	_movement_module.move_towards(self, _player.global_position, chase_speed, patrol_arrive_distance)


func _try_enter_chase_state() -> void:
	if not is_instance_valid(_player):
		return

	var distance_to_player := global_position.distance_to(_player.global_position)
	if distance_to_player > maxf(detect_radius, 0.0):
		return

	_chase_module.reset()
	_state = BeastState.CHASE


func _end_chase_back_to_home() -> void:
	_chase_module.reset()
	_state = BeastState.PATROL_MOVE
	_patrol_target = _spawn_position


func _pick_next_patrol_target() -> void:
	_patrol_target = _patrol_module.next_patrol_point(_spawn_position, patrol_radius)


func _direction_from_velocity() -> Vector2:
	if velocity.length_squared() <= 0.0001:
		return Vector2.ZERO
	return velocity.normalized()


func _resolve_player() -> CharacterBody2D:
	if player_node_path != NodePath():
		var by_path := get_node_or_null(player_node_path)
		if by_path is CharacterBody2D:
			return by_path as CharacterBody2D

	for node in get_tree().get_nodes_in_group("player"):
		if node is CharacterBody2D:
			return node as CharacterBody2D

	var scene_root := get_tree().current_scene
	if scene_root != null:
		var by_name := scene_root.find_child("Player", true, false)
		if by_name is CharacterBody2D:
			return by_name as CharacterBody2D

	return null


func _on_battle_area_body_entered(body: Node) -> void:
	if body == null:
		return
	if body != _player and not body.is_in_group("player"):
		return

	var context := {
		"beast_id": String(beast_id),
		"beast_scene": scene_file_path,
	}
	_battle_module.enter_battle(get_tree(), battle_scene_path, context)
