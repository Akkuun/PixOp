extends Control

enum BlockType { BLUR, COMPRESSION, RESIZE }

@export var block_type: BlockType = BlockType.BLUR
@export var node_work_zone : Control

@onready var label = $ColorRect/Label
@onready var colorRect = $ColorRect
@onready var canvasLayer = $"../../.."

var is_dragging = false # state
var mouse_offset # center mouse on click
var delay = 10
var original_parent # Pour stocker le parent original si nécessaire de revenir

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if colorRect.get_global_rect().has_point(event.global_position):
				is_dragging = true
				mouse_offset = get_global_mouse_position() - global_position
				
				# Sauvegarde la position globale actuelle avant de changer de parent
				var global_pos = global_position
				
				# Sauvegarde le parent original
				original_parent = get_parent()
				
				# Détache du parent actuel et rattache au canvasLayer
				get_parent().remove_child(self)
				canvasLayer.add_child(self)
				
				# Restaure la position globale pour que le nœud reste visuellement au même endroit
				global_position = global_pos
		else:
			is_dragging = false
			# Si vous souhaitez remettre le nœud à son parent d'origine quand on relâche:
			# Décommenter les lignes ci-dessous
			# var global_pos = global_position
			# get_parent().remove_child(self)
			# original_parent.add_child(self)
			# global_position = global_pos

func _physics_process(delta):
	if is_dragging:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", get_global_mouse_position() - mouse_offset, delay * delta)
