extends "res://Lib_Images/image_lib.gd"

enum GraphState {Start, Middle, End}

func display_final_image():
	pass

class Operator extends Resource:
	var name: String
	var requiredParents: int
	var returnedImages = 1
	var function: Callable

	func _init(name: String, function: Callable, requiredParents: int = 0, returnedImages: int = 1) -> void:
		self.name = name
		self.requiredParents = requiredParents
		self.function = function
		self.returnedImages = returnedImages


func _flou_wrapper(img: Image, kernel_size: int) -> Image:
	return await flou(img, kernel_size)
var flou_operator = Operator.new("flou", Callable(self, "_flou_wrapper"), 1, 1)
func _erosion_wrapper(img: Image, kernel_size: int) -> Image:
	return await erosion(img, kernel_size)
var erosion_operator = Operator.new("erosion", Callable(self, "_erosion_wrapper"), 1, 1)
func _dilatation_wrapper(img: Image, kernel_size: int) -> Image:
	return await dilatation(img, kernel_size)
var dilatation_operator = Operator.new("dilatation", Callable(self, "_dilatation_wrapper"), 1, 1)
func _seuil_otsu_wrapper(img: Image) -> Image:
	return await seuil_otsu(img)
var seuil_otsu_operator = Operator.new("seuil_otsu", Callable(self, "_seuil_otsu_wrapper"), 1, 1)
func _difference_wrapper(img1: Image, img2: Image) -> Image:
	return await difference(img1, img2)
var difference_operator = Operator.new("difference", Callable(self, "_difference_wrapper"), 2, 1)
func _negatif_wrapper(img: Image) -> Image:
	return await negatif(img)
var negatif_operator = Operator.new("negatif", Callable(self, "_negatif_wrapper"), 1, 1)
var end_operator = Operator.new("end", Callable(self, "display_final_image"), 1, 0)

class PixopGraphNode extends Resource:
	var state: GraphState
	
	var childs: Array
	var parents: Array
	var operatorApplied: Operator

	var parameters: Dictionary

	func _init(state: GraphState, operatorApplied: Operator = null, parameters: Dictionary = {}, parents: Array = [], child = []) -> void:
		self.state = state
		self.childs = childs
		self.operatorApplied = operatorApplied
		self.parameters = parameters
		self.parents = parents
		for parent in parents:
			parent.add_child(self)

	func add_child(child: PixopGraphNode) -> void:
		childs.append(child)

	func private_remove_parent(parent: PixopGraphNode) -> void:
		var index = parents.find(parent)
		if index != -1:
			parents.remove_at(index)

	func remove_child(child: PixopGraphNode) -> void:
		var index = childs.find(child)
		if index != -1:
			childs[index].private_remove_parent(self)
			childs.remove_at(index)

	func check_conditions() -> bool:
		if state == GraphState.Start:
			return true
		return parents.size() != operatorApplied.requiredParents
	
	func get_last_correct_node() -> PixopGraphNode:
		# TODO (this was garbage generated code, doesn't do what i want)
		if state == GraphState.End:
			return self
		for child in childs:
			var last = child.get_last_correct_node()
			if last != null:
				return last
		return null
	
	func is_graph_full(start: bool = true) -> bool:
		if start:
			if state != GraphState.Start:
				return false
		else:
			if !check_conditions():
				return false
			if state == GraphState.End:
				return true
			var full = true
			for child in childs:
				full = full and child.is_graph_full(false)
			return full
		return true


