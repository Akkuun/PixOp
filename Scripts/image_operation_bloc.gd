extends Control

enum BlockType { BLUR, COMPRESSION, RESIZE }

@export var block_type: BlockType = BlockType.BLUR
@export var node_work_zone : Control

@onready var label = $ColorRect/Label
@onready var colorRect = $ColorRect

var is_dragging = false # state
var mouse_offset # center mouse on click
var delay = 10


func _ready():
	match block_type:
		BlockType.BLUR:
			label.text = "Blur"
		BlockType.COMPRESSION:
			label.text = "Compression"
		BlockType.RESIZE:
			label.text = "Resize"
	
	# Add this to make sure the block is properly sized
	size_flags_horizontal = SIZE_FILL
	size_flags_vertical = SIZE_FILL
	
func _input(event):
	if event is InputEventMouseButton and event.button_index  == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if colorRect.get_global_rect().has_point(event.global_position):
				is_dragging = true
				mouse_offset = get_global_mouse_position() - global_position
		else :
			is_dragging = false

func _physics_process(delta):
	if is_dragging:
		var tween = get_tree().create_tween()
		tween.tween_property(self,"position", get_global_mouse_position(), delay*delta)
