extends Area2D


@export var target_spawn_name: String = ""
@export var target_scene_path: String = ""
@export var player_group: String = "player"
@export var cooldown_sec: float = 0.5


var _last_trigger_time_sec: float = -INF
var _ignored_body_ids: Dictionary = {}


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	if not _has_collision_shape():
		push_warning("Portal '%s' has no CollisionShape2D/CollisionPolygon2D." % name)

	if _resolve_spawn_name().is_empty():
		push_warning("Portal '%s' could not infer target_spawn_name. Fill it manually." % name)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group(player_group):
		return
	if _is_body_ignored(body):
		return
	if _is_on_cooldown(body):
		return

	var spawn_name := _resolve_spawn_name()
	if spawn_name.is_empty():
		push_warning("Portal '%s' has no valid target_spawn_name." % name)
		return

	_last_trigger_time_sec = Time.get_ticks_msec() / 1000.0
	_set_body_cooldown(body)

	if target_scene_path.is_empty():
		_teleport_within_scene(body, spawn_name)
		return

	if SceneFlow == null:
		push_warning("SceneFlow autoload is missing. Add res://autoload/SceneFlow.gd as 'SceneFlow'.")
		return

	SceneFlow.register_player(body)
	SceneFlow.change_scene_with_player(target_scene_path, spawn_name)


func _teleport_within_scene(body: Node, spawn_name: String) -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_warning("Portal '%s' could not find the current scene." % name)
		return

	var spawn := _find_spawn(current_scene, spawn_name)
	if spawn == null:
		push_warning("Portal '%s' could not find spawn '%s'." % [name, spawn_name])
		return

	if body is Node2D:
		(body as Node2D).global_position = spawn.global_position
		if body is CharacterBody2D:
			(body as CharacterBody2D).velocity = Vector2.ZERO
		_mark_nearby_portals_ignored(current_scene, body, spawn.global_position)
	else:
		push_warning("Portal '%s' triggered by a non-Node2D body." % name)


func _on_body_exited(body: Node) -> void:
	if body == null:
		return

	_ignored_body_ids.erase(body.get_instance_id())


func _resolve_spawn_name() -> String:
	if not target_spawn_name.is_empty():
		return target_spawn_name

	var node_name := String(name)
	if node_name.begins_with("to_"):
		return node_name.substr(3)

	return ""


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


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return true
	return false


func ignore_body_until_exit(body: Node) -> void:
	if body == null:
		return

	_ignored_body_ids[body.get_instance_id()] = true


func is_point_near_portal(point: Vector2, extra_radius: float = 0.0) -> bool:
	var portal_node := self as Node2D
	if portal_node == null:
		return false

	var radius := 24.0 + maxf(extra_radius, 0.0)
	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape := child as CollisionShape2D
			if collision_shape.shape is RectangleShape2D:
				radius = maxf(radius, (collision_shape.shape as RectangleShape2D).size.length() * 0.5 + extra_radius)
			elif collision_shape.shape is CircleShape2D:
				radius = maxf(radius, (collision_shape.shape as CircleShape2D).radius + extra_radius)

	return portal_node.global_position.distance_to(point) <= radius


func _mark_nearby_portals_ignored(scene_root: Node, body: Node, spawn_position: Vector2) -> void:
	if scene_root == null or body == null:
		return

	for node in scene_root.find_children("*", "", true, false):
		if node == null or not node.has_method("ignore_body_until_exit"):
			continue
		if not node.has_method("is_point_near_portal"):
			continue
		if bool(node.call("is_point_near_portal", spawn_position, 24.0)):
			node.call("ignore_body_until_exit", body)


func _set_body_cooldown(body: Node) -> void:
	if body == null:
		return

	var until_sec := Time.get_ticks_msec() / 1000.0 + maxf(cooldown_sec, 0.0)
	body.set_meta(&"portal_cooldown_until_sec", until_sec)


func _is_on_cooldown(body: Node) -> bool:
	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec - _last_trigger_time_sec < maxf(cooldown_sec, 0.0):
		return true
	if body != null and body.has_meta(&"portal_cooldown_until_sec"):
		var until_sec = float(body.get_meta(&"portal_cooldown_until_sec"))
		return now_sec < until_sec
	return false


func _is_body_ignored(body: Node) -> bool:
	if body == null:
		return false

	return _ignored_body_ids.has(body.get_instance_id())
