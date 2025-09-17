extends Node

@export var workingImage: Sprite2D

var image_lib: Node

func _ready() -> void:
	image_lib = get_tree().current_scene.get_node(".")




func _on_erosion() -> void:
	pass # Replace with function body.
