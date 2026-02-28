extends RefCounted


var _cooldown_seconds: float = 1.0
var _cooldown_left: float = 0.0
var _entering_battle: bool = false


func _init(cooldown_seconds: float = 1.0) -> void:
	_cooldown_seconds = maxf(cooldown_seconds, 0.0)


func tick(delta: float) -> void:
	if _cooldown_left <= 0.0:
		return
	_cooldown_left = maxf(_cooldown_left - maxf(delta, 0.0), 0.0)


func can_enter_battle() -> bool:
	return _cooldown_left <= 0.0 and not _entering_battle


func enter_battle(scene_tree: SceneTree, battle_scene_path: String, context: Dictionary = {}) -> bool:
	if scene_tree == null:
		return false
	if battle_scene_path.is_empty():
		return false
	if not ResourceLoader.exists(battle_scene_path):
		push_warning("Battle scene not found: %s" % battle_scene_path)
		return false
	if not can_enter_battle():
		return false

	_cooldown_left = _cooldown_seconds
	_entering_battle = true
	call_deferred("_deferred_change_scene", scene_tree, battle_scene_path, context)
	return true


func _deferred_change_scene(scene_tree: SceneTree, battle_scene_path: String, context: Dictionary) -> void:
	_entering_battle = false
	if scene_tree == null:
		_cooldown_left = 0.0
		return

	if not context.is_empty():
		scene_tree.set_meta("battle_context", context)

	var err: Error = scene_tree.change_scene_to_file(battle_scene_path)
	if err != OK:
		_cooldown_left = 0.0
		push_warning("Failed to change battle scene: %s (err=%d)" % [battle_scene_path, err])
