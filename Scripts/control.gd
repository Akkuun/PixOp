extends Node

var workingImage: Sprite2D
var baseImage: Sprite2D

var image_lib: Node

func _ready() -> void:
	image_lib = get_tree().current_scene.get_node(".")
	workingImage = get_tree().current_scene.get_node("WorkingImage") as Sprite2D
	baseImage = get_tree().current_scene.get_node("BaseImage") as Sprite2D
	# log if these two var are null
	if not image_lib:
		print("Error: Image library node not found.")
	else:
		print("Image library node found : ", image_lib.name)
	if not workingImage:
		print("Error: WorkingImage node not found or not a Sprite2D.")
	else :
		print("WorkingImage node found : ", workingImage.name)



func _on_test_button_down() -> void:
	var imgGrey = await image_lib.greyscale(workingImage.texture.get_image())
	workingImage.texture = ImageTexture.create_from_image(imgGrey)


func _on_test_2_button_down() -> void:
	var otsuSeuil = await image_lib.otsu(workingImage.texture.get_image())
	print("Otsu threshold: ", otsuSeuil)
	var imgSeuil = await image_lib.seuil(workingImage.texture.get_image(), [otsuSeuil])

	var imgOuverture = await image_lib.ouverture(imgSeuil, 3)
	var imgDilatation = await image_lib.dilatation(imgOuverture, 5)
	var imgErosion = await image_lib.erosion(imgDilatation, 7)
	workingImage.texture = ImageTexture.create_from_image(imgErosion)

func _on_test_3_button_down() -> void:
	var imgFlouFond = await image_lib.flou_fond(baseImage.texture.get_image(), workingImage.texture.get_image(), 3)
	baseImage.texture = ImageTexture.create_from_image(imgFlouFond)
