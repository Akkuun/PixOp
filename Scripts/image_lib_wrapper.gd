extends "res://Lib_Images/image_lib.gd"

enum GraphState {Start, Middle, End}

func display_final_image():
	pass

class PixopGraphNodeIdentifier extends Resource:
	static var current_id: int = 0

	static func get_next_id() -> int:
		current_id += 1
		return current_id
	
	func _init() -> void:
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

func _flou_fond_wrapper(img: Image, img2: Image, kernel_size: int) -> Image:
	return await flou_fond(img, img2, kernel_size)
var flou_fond_operator = Operator.new("flou_fond", Callable(self, "_flou_fond_wrapper"), 2, 1)
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
func _expansion_dynamique_wrapper(img: Image) -> Image:
	return await expansion_dynamique(img)
var expansion_dynamique_operator = Operator.new("expansion_dynamique", Callable(self, "_expansion_dynamique_wrapper"), 1, 1)
var end_operator = Operator.new("end", Callable(self, "display_final_image"), 1, 0)

class PixopGraphNode extends Resource:
	var state: GraphState
	var id: int
	var name: String
	var childs: Array
	var parents: Array
	var operatorApplied: Operator

	var parameters: Dictionary
	
	# Dictionary to map input port index to parent node
	# Key: int (port index), Value: PixopGraphNode (parent node)
	var port_connections: Dictionary = {}

	func _init(state: GraphState, operatorApplied: Operator = null, parameters: Dictionary = {}, parents: Array = [], name: String = "") -> void:
		id = PixopGraphNodeIdentifier.get_next_id()
		self.state = state
		self.name = name
		self.operatorApplied = operatorApplied
		self.parameters = parameters
		self.parents = parents
		for parent in parents:
			parent.add_child(self)

	func add_child(child: PixopGraphNode, to_port: int = 0) -> void:
		# Only add if not already a child
		if child not in childs:
			childs.append(child)
		# Only add self as parent if not already a parent
		if self not in child.parents:
			child.parents.append(self)
		# Store the port connection mapping
		child.port_connections[to_port] = self

	func private_remove_parent(parent: PixopGraphNode) -> void:
		# Remove ALL instances of this parent (in case there were duplicates)
		while parent in parents:
			var index = parents.find(parent)
			if index != -1:
				parents.remove_at(index)

	func remove_child(child: PixopGraphNode, from_port: int = -1) -> void:
		# Remove ALL instances of this child (in case there were duplicates)
		while child in childs:
			var index = childs.find(child)
			if index != -1:
				childs.remove_at(index)
		# Remove self from child's parents
		child.private_remove_parent(self)
		# Remove the port connection mapping
		if from_port >= 0 and child.port_connections.has(from_port):
			if child.port_connections[from_port] == self:
				child.port_connections.erase(from_port)

	func check_conditions() -> bool:
		if state == GraphState.Start:
			return true
		return parents.size() == operatorApplied.requiredParents
	
	func search_for_end(current_path: Array = []) -> Array:
		# Prevent infinite recursion by checking if we've already visited this node
		if self in current_path:
			return []
		
		# Add this node to the current path
		var new_path = current_path + [self]
		
		# If this is an end node, return the path of nodes leading to it
		if state == GraphState.End:
			return new_path
		
		# If this is a leaf node (no children), return empty array (end not reached)
		if childs.size() == 0:
			return []
		
		# Recursively search through all children
		for child in childs:
			var child_path = child.search_for_end(new_path)
			# If any child found a path to end, return it immediately
			if child_path.size() > 0:
				return child_path
		
		# If no child found a path to end, return empty array
		return []

	func get_nodes_from_start_to_end() -> Array:
		if state != GraphState.Start:
			return []
		var path = search_for_end()
		print("Path from start to end: ", path.size(), " nodes")
		for i in range(path.size()):
			var node = path[i]
			print("  Path[", i, "]: ID=", node.id, " State=", node.state)
		return path

	func search_for_target(target: PixopGraphNode, current_path: Array = []) -> Array:
		# Prevent infinite recursion by checking if we've already visited this node
		if self in current_path:
			return []
		
		# Add this node to the current path
		var new_path = current_path + [self]
		
		# If this is the target node, return the path of nodes leading to it
		if self == target:
			return new_path
		
		# If this is a leaf node (no children), return empty array (target not reached)
		if childs.size() == 0:
			return []
		
		# Recursively search through all children
		for child in childs:
			var child_path = child.search_for_target(target, new_path)
			# If any child found a path to target, return it immediately
			if child_path.size() > 0:
				return child_path
		
		# If no child found a path to target, return empty array
		return []

	func get_nodes_from_start_to_target(target: PixopGraphNode) -> Array:
		if state != GraphState.Start:
			return []
		var path = search_for_target(target)
		print("Path from start to target: ", path.size(), " nodes")
		for i in range(path.size()):
			var node = path[i]
			print("  Path[", i, "]: ID=", node.id, " State=", node.state)
		return path

	func is_correct_node() -> bool:
		var parents_corrects = false;
		for parent in parents:
			parents_corrects = parents_corrects or parent.is_correct_node()
		return check_conditions() and (state == GraphState.Start or parents_corrects)
	
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


