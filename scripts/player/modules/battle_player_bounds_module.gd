extends RefCounted


func resolve_battle_nodes(root: Node) -> Dictionary:
	if root == null:
		return {}

	var middle_wall_area: Area2D = root.get_node_or_null("middle_wall") as Area2D
	var middle_wall_shape: CollisionShape2D = null
	if middle_wall_area != null:
		middle_wall_shape = middle_wall_area.get_node_or_null("CollisionShape2D") as CollisionShape2D

	var wall_area: Area2D = root.get_node_or_null("wall") as Area2D
	var right_wall_shape: CollisionShape2D = null
	var left_wall_shape: CollisionShape2D = null
	var top_wall_shape: CollisionShape2D = null
	var bottom_wall_shape: CollisionShape2D = null
	if wall_area != null:
		right_wall_shape = wall_area.get_node_or_null("right_wall") as CollisionShape2D
		left_wall_shape = wall_area.get_node_or_null("left_wall") as CollisionShape2D
		top_wall_shape = wall_area.get_node_or_null("top_wall") as CollisionShape2D
		bottom_wall_shape = wall_area.get_node_or_null("walk_wall") as CollisionShape2D

	return {
		"middle_wall_area": middle_wall_area,
		"middle_wall_shape": middle_wall_shape,
		"wall_area": wall_area,
		"right_wall_shape": right_wall_shape,
		"left_wall_shape": left_wall_shape,
		"top_wall_shape": top_wall_shape,
		"bottom_wall_shape": bottom_wall_shape
	}


func refresh_wall_limits(
	right_wall_shape: CollisionShape2D,
	left_wall_shape: CollisionShape2D,
	top_wall_shape: CollisionShape2D,
	bottom_wall_shape: CollisionShape2D
) -> Dictionary:
	if right_wall_shape == null or left_wall_shape == null or top_wall_shape == null or bottom_wall_shape == null:
		return {
			"has_limits": false,
			"left": -INF,
			"right": INF,
			"top": -INF,
			"bottom": INF
		}

	var left_aabb: Rect2 = _shape_world_aabb(right_wall_shape)
	var right_aabb: Rect2 = _shape_world_aabb(left_wall_shape)
	var top_aabb: Rect2 = _shape_world_aabb(top_wall_shape)
	var bottom_aabb: Rect2 = _shape_world_aabb(bottom_wall_shape)

	if left_aabb.size == Vector2.ZERO or right_aabb.size == Vector2.ZERO or top_aabb.size == Vector2.ZERO or bottom_aabb.size == Vector2.ZERO:
		return {
			"has_limits": false,
			"left": -INF,
			"right": INF,
			"top": -INF,
			"bottom": INF
		}

	return {
		"has_limits": true,
		"left": left_aabb.position.x + left_aabb.size.x,
		"right": right_aabb.position.x,
		"top": top_aabb.position.y + top_aabb.size.y,
		"bottom": bottom_aabb.position.y
	}


func configure_camera_limits(
	camera: Camera2D,
	has_limits: bool,
	left_limit: float,
	right_limit: float,
	top_limit: float,
	bottom_limit: float
) -> void:
	if camera == null or not has_limits:
		return
	camera.limit_enabled = true
	camera.limit_left = int(floor(left_limit))
	camera.limit_right = int(ceil(right_limit))
	camera.limit_top = int(floor(top_limit))
	camera.limit_bottom = int(ceil(bottom_limit))


func apply_middle_wall_block(
	direction: Vector2,
	is_jumping: bool,
	middle_wall_area: Area2D,
	sensor_area: Area2D,
	global_position: Vector2
) -> Vector2:
	if direction == Vector2.ZERO:
		return direction
	if is_jumping:
		return direction
	if middle_wall_area == null or sensor_area == null:
		return direction
	if not sensor_area.overlaps_area(middle_wall_area):
		return direction

	var blocked: Vector2 = direction
	var middle_y: float = middle_wall_area.global_position.y

	if global_position.y < middle_y and blocked.y > 0.0:
		blocked.y = 0.0
	elif global_position.y > middle_y and blocked.y < 0.0:
		blocked.y = 0.0

	return blocked


func clamp_player_inside_wall_bounds(
	global_position: Vector2,
	body_collision_shape: CollisionShape2D,
	has_limits: bool,
	left_limit: float,
	right_limit: float,
	top_limit: float,
	bottom_limit: float
) -> Dictionary:
	var hit_state: Dictionary = {
		"left": false,
		"right": false,
		"top": false,
		"bottom": false
	}

	if not has_limits or body_collision_shape == null or body_collision_shape.shape == null:
		return {
			"position": global_position,
			"hit_state": hit_state
		}

	var half_extents: Vector2 = _get_body_half_extents(body_collision_shape)
	var min_x: float = left_limit + half_extents.x
	var max_x: float = right_limit - half_extents.x
	var min_y: float = top_limit + half_extents.y
	var max_y: float = bottom_limit - half_extents.y

	if min_x > max_x:
		var center_x: float = (left_limit + right_limit) * 0.5
		min_x = center_x
		max_x = center_x
	if min_y > max_y:
		var center_y: float = (top_limit + bottom_limit) * 0.5
		min_y = center_y
		max_y = center_y

	var clamped_position := Vector2(
		clampf(global_position.x, min_x, max_x),
		clampf(global_position.y, min_y, max_y)
	)

	var epsilon: float = 0.001
	hit_state["left"] = clamped_position.x <= min_x + epsilon and global_position.x < min_x
	hit_state["right"] = clamped_position.x >= max_x - epsilon and global_position.x > max_x
	hit_state["top"] = clamped_position.y <= min_y + epsilon and global_position.y < min_y
	hit_state["bottom"] = clamped_position.y >= max_y - epsilon and global_position.y > max_y

	return {
		"position": clamped_position,
		"hit_state": hit_state
	}


func _get_body_half_extents(body_collision_shape: CollisionShape2D) -> Vector2:
	if body_collision_shape == null or body_collision_shape.shape == null:
		return Vector2.ZERO
	var shape := body_collision_shape.shape
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size * 0.5 * body_collision_shape.global_scale.abs()
	if shape is CircleShape2D:
		var r: float = (shape as CircleShape2D).radius
		var s: Vector2 = body_collision_shape.global_scale.abs()
		return Vector2(r * s.x, r * s.y)
	return Vector2.ZERO


func _shape_world_aabb(collision_shape: CollisionShape2D) -> Rect2:
	if collision_shape == null or collision_shape.shape == null:
		return Rect2()

	var points: Array[Vector2] = []
	var shape := collision_shape.shape

	if shape is RectangleShape2D:
		var half_size: Vector2 = (shape as RectangleShape2D).size * 0.5
		points = [
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y)
		]
	elif shape is CircleShape2D:
		var radius: float = (shape as CircleShape2D).radius
		points = [
			Vector2(-radius, -radius),
			Vector2(radius, -radius),
			Vector2(radius, radius),
			Vector2(-radius, radius)
		]
	else:
		return Rect2(collision_shape.global_position, Vector2.ZERO)

	var xform: Transform2D = collision_shape.global_transform
	var world_point: Vector2 = xform * points[0]
	var min_point: Vector2 = world_point
	var max_point: Vector2 = world_point

	for index in range(1, points.size()):
		world_point = xform * points[index]
		min_point.x = minf(min_point.x, world_point.x)
		min_point.y = minf(min_point.y, world_point.y)
		max_point.x = maxf(max_point.x, world_point.x)
		max_point.y = maxf(max_point.y, world_point.y)

	return Rect2(min_point, max_point - min_point)
