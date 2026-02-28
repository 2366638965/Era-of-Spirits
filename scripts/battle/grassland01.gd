extends Node2D


@export var debug_print_context: bool = true


var battle_context: Dictionary = {}


func _ready() -> void:
	battle_context = _consume_battle_context()
	if debug_print_context:
		print("[Grassland01] battle_context=", battle_context)


func _consume_battle_context() -> Dictionary:
	var scene_tree := get_tree()
	if scene_tree == null:
		return {}

	if not scene_tree.has_meta("battle_context"):
		return {}

	var context = scene_tree.get_meta("battle_context")
	scene_tree.remove_meta("battle_context")

	if context is Dictionary:
		return context
	return {}
