extends "res://Scripts/image_lib_wrapper.gd"

var images_folder = "res://Images"

var startNode: PixopGraphNode
var endNode: PixopGraphNode

var definedW = 192.0
var definedH = 256.0

# Dictionary to map GraphNode names to their PixopGraphNode instances
@export var graph_node_map: Dictionary = {}

@export var current: Sprite2D
@export var target: Sprite2D
@export var graph_edit : GraphEdit

func load_level(id: int) -> void:
	startNode = PixopGraphNode.new(GraphState.Start)
	endNode = PixopGraphNode.new(GraphState.End, end_operator)
	graph_node_map.clear()
	graph_node_map["Start_node"] = startNode
	graph_node_map["Final_node"] = endNode
	var level_path = images_folder + "/" + str(id)
	var texCurrent := load(level_path + "/current.png")
	current.texture = texCurrent
	var imgW = current.texture.get_width()
	var imgH = current.texture.get_height()
	current.scale = Vector2(definedW / imgW, definedH / imgH)
	var texTarget := load(level_path + "/target.png")
	target.texture = texTarget
	target.scale = Vector2(definedW / imgW, definedH / imgH)

func _ready() -> void:
	# Add this node to the "game" group so other scripts can find it
	add_to_group("game")
	
	load_level(0)
	
	# Connect GraphEdit signals
	if graph_edit:
		graph_edit.connection_request.connect(_on_graph_edit_connection_request)
		graph_edit.disconnection_request.connect(_on_graph_edit_disconnection_request)
		graph_edit.connection_drag_started.connect(_on_graph_edit_connection_drag_started)
		graph_edit.connection_drag_ended.connect(_on_graph_edit_connection_drag_ended)
		print("GraphEdit signals connected successfully")
	else:
		print("Warning: GraphEdit node not found")

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


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("Connection request: ", from_node, ":", from_port, " -> ", to_node, ":", to_port)

	
	# Get the PixopGraphNode instances
	var from_pixop_node = graph_node_map.get(from_node)
	var to_pixop_node = graph_node_map.get(to_node)

	print("Found PixopGraphNodes - From: ", from_pixop_node != null, " To: ", to_pixop_node != null)
	
	if from_pixop_node and to_pixop_node:
		print("Found both PixopGraphNodes - updating connections")
		# Update the PixopGraphNode connections
		from_pixop_node.add_child(to_pixop_node)
		
		# Allow the GraphEdit connection
		graph_edit.connect_node(from_node, from_port, to_node, to_port)
		
		print("✓ Successfully connected: ", from_node, " -> ", to_node)
		print("  From node children count: ", from_pixop_node.childs.size())
		print("  To node parents count: ", to_pixop_node.parents.size())
	else:
		print("✗ Connection failed - missing PixopGraphNodes:")
		print("  From node (", from_node, "): ", "Found" if from_pixop_node else "Not found")
		print("  To node (", to_node, "): ", "Found" if to_pixop_node else "Not found")

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("Disconnection request: ", from_node, ":", from_port, " -> ", to_node, ":", to_port)
	
	# Get the actual GraphNode instances using the GraphEdit
	var graph_node_from = graph_edit.get_node(NodePath(from_node))
	var graph_node_to = graph_edit.get_node(NodePath(to_node))
	
	print("Found GraphNodes - From: ", graph_node_from != null, " To: ", graph_node_to != null)
	
	# Get the PixopGraphNode instances
	var from_pixop_node = null
	if graph_node_from and graph_node_from.has_method("get_pixop_graph_node"):
		from_pixop_node = graph_node_from.get_pixop_graph_node()

	var to_pixop_node = null
	if graph_node_to and graph_node_to.has_method("get_pixop_graph_node"):
		to_pixop_node = graph_node_to.get_pixop_graph_node()
	
	if from_pixop_node and to_pixop_node:
		print("Found both PixopGraphNodes - updating disconnections")
		# Update the PixopGraphNode connections
		from_pixop_node.remove_child(to_pixop_node)
		
		# Allow the GraphEdit disconnection
		graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
		
		print("✓ Successfully disconnected: ", from_node, " -> ", to_node)
		print("  From node children count: ", from_pixop_node.childs.size())
		print("  To node parents count: ", to_pixop_node.parents.size())
	else:
		print("✗ Disconnection failed - missing PixopGraphNodes:")
		print("  From node (", from_node, "): ", "Found" if from_pixop_node else "Not found")
		print("  To node (", to_node, "): ", "Found" if to_pixop_node else "Not found")

func _on_graph_edit_connection_drag_started(_from_node: StringName, _from_port: int, _is_output: bool) -> void:
	print("Started dragging connection from: ", _from_node, " port: ", _from_port, " output: ", _is_output)

func _on_graph_edit_connection_drag_ended() -> void:
	print("Connection drag ended")

# Helper function to register GraphNodes (no longer needed with direct access method)
func register_graph_node(graph_node_name: String, operator: String) -> void:
	var new_pixop_node = null
	# Toby fox my love
	if operator == "start":
		new_pixop_node = startNode
	elif operator == "final":
		new_pixop_node = endNode
	elif operator == "blur":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, flou_operator, {"kernel_size": 5})
	elif operator == "dilatation":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, dilatation_operator, {"kernel_size": 5})
	elif operator == "erosion":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, erosion_operator, {"kernel_size": 5})
	elif operator == "seuil_otsu":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, seuil_otsu_operator, {})
	elif operator == "difference":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, difference_operator, {})
	elif operator == "negatif":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, negatif_operator, {})
	elif operator == "blur_background":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, flou_operator, {"kernel_size": 5})
	elif operator == "rgb_to_ycbcr":
		# Placeholder for future operator
		print("Warning: rgb_to_ycbcr operator not implemented yet")
		return
	elif operator == "ycbcr_to_rgb":
		# Placeholder for future operator
		print("Warning: ycbcr_to_rgb operator not implemented yet")
		return
	if new_pixop_node == null:
		print("Warning: Could not create PixopGraphNode for operator '", operator, "'")
		return
	graph_node_map[graph_node_name] = new_pixop_node
	print("Registered GraphNode '", graph_node_name, "' with operator '", operator, "'")

# Helper function to validate if a connection is allowed
func validate_connection(from_node: StringName, to_node: StringName) -> bool:
	var from_pixop_node = graph_node_map.get(from_node)
	var to_pixop_node = graph_node_map.get(to_node)
	
	if not from_pixop_node or not to_pixop_node:
		return false
	
	# Check if the connection would create a valid graph
	if to_pixop_node.operatorApplied and to_pixop_node.parents.size() >= to_pixop_node.operatorApplied.requiredParents:
		print("Node already has enough parents")
		return false
	
	return true
