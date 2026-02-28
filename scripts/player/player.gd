extends CharacterBody2D

@export var move_speed: float = 160.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const PlayerInputModule = preload("res://scripts/player/modules/player_input_module.gd")
const PlayerMovementModule = preload("res://scripts/player/modules/player_movement_module.gd")
const PlayerAnimationModule = preload("res://scripts/player/modules/player_animation_module.gd")

var input_module
var movement_module
var animation_module


func _ready() -> void:
	input_module = PlayerInputModule.new()
	movement_module = PlayerMovementModule.new()
	animation_module = PlayerAnimationModule.new(animated_sprite)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = input_module.get_move_direction()
	movement_module.move(self, direction, move_speed)
	animation_module.update(direction)