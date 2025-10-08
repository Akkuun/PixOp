extends Node2D

@export var lutz: Sprite2D
@export var lutz_mouth: Sprite2D

@export var running: bool

var default_mouth_position: Vector2

var translation_vector = Vector2(169.0 - 156.0, 169.0 - 134.0)
var max_translation_distance: float = 0.25
var time_since_start: float = 0.0
var base_speed: float = 10.0
var random_speed: float = 1.0
var last_value: float = -1.0


func _ready() -> void:
	default_mouth_position = lutz_mouth.position
	running = true

func start_animation() -> void:
	running = true
	time_since_start = 0.0
	last_value = 0.0

func _process(delta: float) -> void:
	if not running:
		return

	time_since_start += delta

	# The mouth should move along a vector that is oriented towards translation angle
	var translation_distance = abs(max_translation_distance * sin(time_since_start * base_speed))
	lutz_mouth.position = default_mouth_position + translation_vector * translation_distance 

