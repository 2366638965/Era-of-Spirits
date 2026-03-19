extends RefCounted
# Function Description:
# Resolves player targets and distance checks for chase/attack decisions.


func resolve_player(owner: Node, player_node_path: NodePath) -> CharacterBody2D:
	if owner == null:
		return null

	if player_node_path != NodePath():
		var by_path: Node = owner.get_node_or_null(player_node_path)
		if by_path is CharacterBody2D:
			return by_path as CharacterBody2D

	var tree := owner.get_tree()
	if tree == null:
		return null

	for node in tree.get_nodes_in_group("player"):
		if node is CharacterBody2D:
			return node as CharacterBody2D

	var scene_root: Node = tree.current_scene
	if scene_root != null:
		var by_name: Node = scene_root.find_child("battlep", true, false)
		if by_name is CharacterBody2D:
			return by_name as CharacterBody2D

	return null


func has_valid_target(target: CharacterBody2D) -> bool:
	return is_instance_valid(target)


func distance_to_target(owner_position: Vector2, target: CharacterBody2D) -> float:
	if not has_valid_target(target):
		return INF
	return owner_position.distance_to(target.global_position)


func is_in_chase_range(distance_to_target_value: float, chase_range: float) -> bool:
	return distance_to_target_value <= maxf(chase_range, 0.0)


func is_in_attack_range(distance_to_target_value: float, attack_range: float) -> bool:
	return distance_to_target_value <= maxf(attack_range, 0.0)


func should_run(distance_to_target_value: float, run_range: float) -> bool:
	return distance_to_target_value > maxf(run_range, 0.0)
