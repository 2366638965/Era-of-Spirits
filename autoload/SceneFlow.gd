extends Node


var _player: Node = null
var _transition_in_progress: bool = false


func register_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		push_warning("SceneFlow.register_player received an invalid player.")
		return

	_player = player


func change_scene_with_player(target_scene_path: String, spawn_name: String) -> void:
	if target_scene_path.is_empty():
		push_warning("SceneFlow.change_scene_with_player requires a target_scene_path.")
		return
	if spawn_name.is_empty():
		push_warning("SceneFlow.change_scene_with_player requires a spawn_name.")
		return
	if _player == null or not is_instance_valid(_player):
		push_warning("SceneFlow has no registered player to move between scenes.")
		return
	if not ResourceLoader.exists(target_scene_path):
		push_warning("Target scene not found: %s" % target_scene_path)
		return
	if _transition_in_progress:
		return

	_transition_in_progress = true
	call_deferred("_deferred_change_scene_with_registered_player", target_scene_path, spawn_name)


func _deferred_change_scene_with_registered_player(target_scene_path: String, spawn_name: String) -> void:
	var scene_tree := get_tree()
	if scene_tree == null:
		push_warning("SceneFlow could not access SceneTree.")
		_transition_in_progress = false
		return

	_set_player_transition_state(true)

	if _player.get_parent() != null:
		_player.reparent(scene_tree.root, true)
	else:
		scene_tree.root.add_child(_player)

	var err := scene_tree.change_scene_to_file(target_scene_path)
	if err != OK:
		push_warning("Failed to change scene to %s (err=%d)." % [target_scene_path, err])
		if _player.get_parent() == scene_tree.root:
			scene_tree.root.remove_child(_player)
		_set_player_transition_state(false)
		_transition_in_progress = false
		return

	await scene_tree.process_frame
	await scene_tree.process_frame

	var new_scene := scene_tree.current_scene
	if new_scene == null:
		push_warning("New scene was not ready after changing to %s." % target_scene_path)
		_set_player_transition_state(false)
		_transition_in_progress = false
		return

	_cleanup_duplicate_players(new_scene)

	var spawn := _find_spawn(new_scene, spawn_name)
	if spawn == null:
		push_warning("Spawn '%s' was not found in scene %s." % [spawn_name, target_scene_path])
		_set_player_transition_state(false)
		_transition_in_progress = false
		return

	if _player.get_parent() != null:
		_player.reparent(new_scene, true)
	else:
		new_scene.add_child(_player)

	if _player is Node2D:
		(_player as Node2D).global_position = spawn.global_position
		if _player is CharacterBody2D:
			(_player as CharacterBody2D).velocity = Vector2.ZERO
		_ignore_nearby_portals(new_scene, spawn.global_position)
	else:
		push_warning("Registered player is not a Node2D and cannot be positioned.")

	await scene_tree.physics_frame
	_set_player_transition_state(false)
	_transition_in_progress = false


func _find_spawn(scene_root: Node, spawn_name: String) -> Node2D:
	if scene_root == null or spawn_name.is_empty():
		return null

	var spawns_root := scene_root.get_node_or_null(^"Spawns")
	if spawns_root != null:
		var by_path := spawns_root.get_node_or_null(NodePath(spawn_name))
		if by_path is Node2D:
			return by_path as Node2D

	var fallback := scene_root.find_child(spawn_name, true, false)
	if fallback is Node2D:
		return fallback as Node2D

	return null


func _cleanup_duplicate_players(scene_root: Node) -> void:
	for node in scene_root.find_children("*", "", true, false):
		if node == _player:
			continue
		if not (node is Node):
			continue
		if node.is_in_group("player") or node.name == "Player":
			node.queue_free()


func _set_player_transition_state(is_transitioning: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_player.set_physics_process(not is_transitioning)
	if _player is CharacterBody2D:
		(_player as CharacterBody2D).velocity = Vector2.ZERO

	for node in _player.find_children("*", "", true, false):
		if node is CollisionShape2D or node is CollisionPolygon2D:
			node.set_deferred("disabled", is_transitioning)


func _ignore_nearby_portals(scene_root: Node, spawn_position: Vector2) -> void:
	if scene_root == null or _player == null or not is_instance_valid(_player):
		return

	for node in scene_root.find_children("*", "", true, false):
		if node == null or not node.has_method("ignore_body_until_exit"):
			continue
		if not node.has_method("is_point_near_portal"):
			continue
		if bool(node.call("is_point_near_portal", spawn_position, 24.0)):
			node.call("ignore_body_until_exit", _player)
