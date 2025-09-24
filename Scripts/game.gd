extends "res://Scripts/image_lib_wrapper.gd"

var images_folder = "res://Images"

var startNode: PixopGraphNode
var endNode: PixopGraphNode

@export var current: Sprite2D
@export var target: Sprite2D

func load_level(id: int) -> void:
	startNode = PixopGraphNode.new(GraphState.Start)
	endNode = PixopGraphNode.new(GraphState.End, end_operator)
	var level_path = images_folder + "/" + str(id)
	var texCurrent := load(level_path + "/current.png")
	current.texture = texCurrent
	var texTarget := load(level_path + "/target.png")
	target.texture = texTarget

func _ready() -> void:
	load_level(0)

func _on_flou_button_down() -> void:
	var newNode = PixopGraphNode.new(GraphState.Middle, flou_operator, {"kernel_size": 5}, [startNode])
	startNode.add_child(newNode)
	
	var newImg = await newNode.operatorApplied.function.call(current.texture.get_image(), newNode.parameters["kernel_size"])
	var texNew := ImageTexture.create_from_image(newImg)
	current.texture = texNew
	



func _on_dilatation_button_down() -> void:
	var newNode = PixopGraphNode.new(GraphState.Middle, dilatation_operator, {"kernel_size": 5}, [startNode])
	startNode.add_child(newNode)

	var newImg = await newNode.operatorApplied.function.call(current.texture.get_image(), newNode.parameters["kernel_size"])
	var texNew := ImageTexture.create_from_image(newImg)
	current.texture = texNew

func _on_erosion_button_down() -> void:
	var newNode = PixopGraphNode.new(GraphState.Middle, erosion_operator, {"kernel_size": 5}, [startNode])
	startNode.add_child(newNode)

	var newImg = await newNode.operatorApplied.function.call(current.texture.get_image(), newNode.parameters["kernel_size"])
	var texNew := ImageTexture.create_from_image(newImg)
	current.texture = texNew

func _on_seuil_otsu_button_down() -> void:
	var newNode = PixopGraphNode.new(GraphState.Middle, seuil_otsu_operator, {}, [startNode])
	startNode.add_child(newNode)

	var newImg = await newNode.operatorApplied.function.call(current.texture.get_image())
	var texNew := ImageTexture.create_from_image(newImg)
	current.texture = texNew


func _on_difference_button_down() -> void:
	var newNode = PixopGraphNode.new(GraphState.Middle, difference_operator, {}, [startNode])
	startNode.add_child(newNode)

	var newImg = await newNode.operatorApplied.function.call(current.texture.get_image(), target.texture.get_image())
	var texNew := ImageTexture.create_from_image(newImg)
	current.texture = texNew


func _on_negatif_button_down() -> void:
	var newNode = PixopGraphNode.new(GraphState.Middle, negatif_operator, {}, [startNode])
	startNode.add_child(newNode)

	var newImg = await newNode.operatorApplied.function.call(current.texture.get_image())
	var texNew := ImageTexture.create_from_image(newImg)
	current.texture = texNew
