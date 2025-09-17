extends Node

var workingImage: Sprite2D

var image_lib: Node

func _ready() -> void:
	image_lib = get_tree().current_scene.get_node(".")
	workingImage = get_tree().current_scene.get_node("WorkingImage") as Sprite2D
	# log if these two var are null
	if not image_lib:
		print("Error: Image library node not found.")
	else:
		print("Image library node found : ", image_lib.name)
	if not workingImage:
		print("Error: WorkingImage node not found or not a Sprite2D.")
	else :
		print("WorkingImage node found : ", workingImage.name)




func _on_erosion() -> void:
	var shaderMaterial = image_lib.flou(workingImage.texture.get_image(), 5)
	workingImage.material = shaderMaterial
