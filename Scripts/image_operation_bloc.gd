extends Control

enum BlockType { BLUR, COMPRESSION, RESIZE }
enum ConfigBlock {ONEBYONE,ONEBYTHREE,THREEBYONE,TWOBYONE}

@export var block_type: BlockType = BlockType.BLUR
@export var node_work_zone : Control
@export var config_type: ConfigBlock

@onready var label = $ColorRect/Label
@onready var colorRect = $ColorRect
@onready var canvasLayer = $"../../.."
@onready var work_zone = $"../../WorkZone/ColorRect"
@onready var inputPin1 = $ColorRect/inputPin1
@onready var inputPin2 = $ColorRect/inputPin2
@onready var inputPin3 = $ColorRect/inputPin3
@onready var outputPin1 = $ColorRect/outputPin1
@onready var outputPin2 = $ColorRect/outputPin2
@onready var outputPin3 = $ColorRect/outputPin3

var is_dragging = false # state
var mouse_offset # center mouse on click
var delay = 10
var original_parent # mandatory to came back if needed
var original_position # to store original position

var availableOutpitPins = []
var availableInputPins = []


func _ready():
	inputPin1.visible= false
	inputPin2.visible= false
	inputPin3.visible= false
	outputPin1.visible=false
	outputPin2.visible=false
	outputPin3.visible=false
	match block_type:
		BlockType.BLUR:
			label.text = "Blur"
		BlockType.COMPRESSION:
			label.text = "Compression"
		BlockType.RESIZE:
			label.text = "Resize"
	match config_type:
		ConfigBlock.ONEBYONE:
			inputPin2.visible=true
			outputPin2.visible=true
			availableInputPins.append(inputPin2)
			availableOutpitPins.append(outputPin2)
		
		ConfigBlock.ONEBYTHREE:
			inputPin2.visible=true
			outputPin1.visible=true
			outputPin2.visible=true
			outputPin3.visible=true
			availableInputPins.append(inputPin2)
			availableOutpitPins.append(outputPin1)
			availableOutpitPins.append(outputPin2)
			availableOutpitPins.append(outputPin3)
		ConfigBlock.THREEBYONE:
			inputPin1.visible=true
			inputPin2.visible=true
			inputPin3.visible=true
			outputPin2.visible=true
			availableInputPins.append(inputPin1)
			availableInputPins.append(inputPin1)
			availableInputPins.append(inputPin2)
			availableOutpitPins.append(outputPin2)
		ConfigBlock.TWOBYONE:
			inputPin1.visible=true
			inputPin3.visible=true
			outputPin2.visible=true
			availableInputPins.append(inputPin1)
			availableInputPins.append(inputPin3)
			availableOutpitPins.append(outputPin2)
	# Add this to make sure the block is properly sized
	size_flags_horizontal = SIZE_FILL
	size_flags_vertical = SIZE_FILL
	
func _input(event):
	# if click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# pressed
		if event.pressed:
			# rect position
			if colorRect.get_global_rect().has_point(event.global_position):
				is_dragging = true
				mouse_offset = get_global_mouse_position() - global_position
				
				# save before changing parent
				original_position = global_position
				
				# save current parent
				original_parent = get_parent()
				
				# detatch and set new parent
				get_parent().remove_child(self)
				canvasLayer.add_child(self)
				
				# Restore global position so node stays visually in the same place
				global_position = original_position
		else:
			# mouse released
			if is_dragging:
				is_dragging = false
				
				# Check if the block is inside the work_zone
				var in_work_zone = work_zone.get_global_rect().has_point(global_position)
				
				if not in_work_zone:
					# Store current global position
					var save_global_pos = global_position
					
					# Remove from current parent
					get_parent().remove_child(self)
					
					# Add back to original parent
					original_parent.add_child(self)
					
					# Reset position in original parent's coordinate system
					# Convert global position to parent-local position
					var local_pos = original_parent.get_global_transform().affine_inverse() * save_global_pos
					position = local_pos
					
					print("Block returned to original position")
				else:
					print("Block placed in work zone")

func _physics_process(delta):
	if is_dragging:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", get_global_mouse_position() - mouse_offset, delay * delta)
