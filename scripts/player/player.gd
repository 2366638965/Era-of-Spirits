extends CharacterBody2D

@export var run_speed: float = 160.0
@export var walk_speed: float = 90.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const PlayerInputModule = preload("res://scripts/player/modules/player_input_module.gd")
const PlayerMovementModule = preload("res://scripts/player/modules/player_movement_module.gd")
const PlayerAnimationModule = preload("res://scripts/player/modules/player_animation_module.gd")

var input_module
var movement_module
var animation_module


func _ready() -> void:
	add_to_group("player")
	input_module = PlayerInputModule.new()
	movement_module = PlayerMovementModule.new()
	animation_module = PlayerAnimationModule.new(animated_sprite)


func _physics_process(_delta: float) -> void:
	var move_intent: Dictionary = input_module.get_move_intent()
	var direction: Vector2 = move_intent.get("direction", Vector2.ZERO)
	var is_running: bool = bool(move_intent.get("is_running", false))
	var speed: float = run_speed if is_running else walk_speed
	movement_module.move(self, direction, speed)
	animation_module.update(direction, is_running)
