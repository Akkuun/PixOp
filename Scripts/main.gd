extends "res://Scripts/image_lib_wrapper.gd"

# Preload the particle scene
const PARTICLE_SCENE = preload("res://prefab/node_particles.tscn")
const CONFETTI_SCENE = preload("res://prefab/confettis_particles.tscn")

var images_folder = "res://Levels"

var startNode: PixopGraphNode
var endNode: PixopGraphNode

var definedW = 192.0
var definedH = 256.0

var levelId: int = 0

var baseImage: Image
var targetImage: Image

var dialog: String = ""
var psnr_start: float = 0.0
var psnr_goal: float = 200.0

# Dictionary to map GraphNode names to their PixopGraphNode instances
@export var graph_node_map: Dictionary = {}

@export var current: Sprite2D
@export var target: Sprite2D
@export var graph_edit : GraphEdit

@export var PSNRMeterFill: Sprite2D
@export var ConfettiPosition: Node2D
@export var psnr_anim_duration: float = 0.5

var dialogue_system: Control  # Référence au système de dialogue

func animate_psnr_meter(value: float) -> void:
	# normalization
	var normalized_value = (value / psnr_goal)
	var clamped_value = clamp(normalized_value, 0.0, 1.0)
	# make the value closest to the goal have more precision
	clamped_value = pow(clamped_value, 1.5)

	var tween = create_tween()
	tween.tween_property(PSNRMeterFill, "scale:y", clamped_value, psnr_anim_duration)

	# If level is won, display confetti
	if clamped_value >= (0.99999):
		tween.finished.connect(_spawn_success_confetti, CONNECT_ONE_SHOT)

func _spawn_success_confetti() -> void:
	if not PSNRMeterFill:
		print("Warning: PSNRMeterFill not found for confetti spawn")
		return
	
	# Instance the confetti scene
	var confetti_instance = CONFETTI_SCENE.instantiate()
	get_tree().current_scene.add_child(confetti_instance)
	confetti_instance.global_position = ConfettiPosition.global_position
	
	# Start the confetti emission if it has a GPUParticles2D
	var gpu_particles = confetti_instance.get_node_or_null("GPUParticles2D")
	if gpu_particles:
		gpu_particles.restart()
	
	# Auto-remove the confetti node after emission
	var timer = Timer.new()
	timer.wait_time = confetti_instance.get_node("GPUParticles2D").lifetime * 1.1
	timer.one_shot = true
	timer.timeout.connect(_remove_particles.bind(confetti_instance))
	confetti_instance.add_child(timer)
	timer.start()

func spawn_connection_particles(from_node_name: String, to_node_name: String) -> void:
	# Get the GraphNode instances to find their positions
	var from_graph_node = graph_edit.get_node_or_null(from_node_name)
	var to_graph_node = graph_edit.get_node_or_null(to_node_name)
	
	if not from_graph_node or not to_graph_node:
		print("Could not find GraphNodes for particle spawn: ", from_node_name, " or ", to_node_name)
		return

	var connection_position = graph_edit.get_local_mouse_position()
	connection_position += graph_edit.global_position
	
	# Instance the particle scene
	var particle_instance = PARTICLE_SCENE.instantiate()
	get_tree().current_scene.add_child(particle_instance)
	particle_instance.global_position = connection_position
	
	# Start the particle emission
	var gpu_particles = particle_instance.get_node("GPUParticles2D")
	gpu_particles.restart()
	
	# Auto-remove the particle node after emission is complete
	var timer = Timer.new()
	timer.wait_time = particle_instance.get_node("GPUParticles2D").lifetime * 1.1
	timer.one_shot = true
	timer.timeout.connect(_remove_particles.bind(particle_instance))
	particle_instance.add_child(timer)
	timer.start()

func _remove_particles(particle_node: Node) -> void:
	if particle_node and is_instance_valid(particle_node):
		particle_node.queue_free()

func load_level(id: int) -> void:
	levelId = id
	startNode = PixopGraphNode.new(GraphState.Start)
	endNode = PixopGraphNode.new(GraphState.End, end_operator)
	graph_node_map.clear()
	graph_node_map["Start_node"] = startNode
	graph_node_map["Final_node"] = endNode
	var level_path = images_folder + "/" + str(id)
	var texCurrent := load(level_path + "/current.png")
	var texTarget := load(level_path + "/target.png")
	baseImage = texCurrent.get_image()
	targetImage = texTarget.get_image()

	var level_data = FileAccess.get_file_as_string("res://Levels/levels_data.json")
	
	var json = JSON.new()
	var error = json.parse(level_data)
	if error != OK:
		push_error("Failed to parse levels_data.json: " + str(error))
		return
	var level_data_dict = json.data
	print("Level data dict: ", level_data_dict)

	dialog = level_data_dict.get(str(id)).get("dialog")
	psnr_start = level_data_dict.get(str(id)).get("psnr_start")
	psnr_goal = level_data_dict.get(str(id)).get("psnr_goal")
	animate_psnr_meter(psnr_start) # Reset PSNR meter at level start
	print("Loaded level ", id, ": dialog=", dialog, " psnr_start=", psnr_start, " psnr_goal=", psnr_goal)

	update_current(baseImage)
	update_target(targetImage)


	show_tutorial_dialogue(id)

func update_current(image: Image) -> void:
	var texture := ImageTexture.create_from_image(image)
	current.texture = texture
	var imgW = texture.get_width()
	var imgH = texture.get_height()
	current.scale = Vector2(definedW / imgW, definedH / imgH)

func update_target(image: Image) -> void:
	var texture := ImageTexture.create_from_image(image)
	target.texture = texture
	var imgW = texture.get_width()
	var imgH = texture.get_height()
	target.scale = Vector2(definedW / imgW, definedH / imgH)

func show_tutorial_dialogue(id: int) -> void:
	"""
	Affiche le dialogue de tutoriel correspondant au niveau.
	"""
	# Si dialogue_system n'est pas défini, essayer de le trouver automatiquement
	if dialogue_system == null:
		# Chercher dans le chemin spécifique de la scène
		dialogue_system = get_node_or_null("TutorialUI/Lutz Animation/TextureRect")
		
		if dialogue_system == null:
			dialogue_system = get_node_or_null("../DialogueSystem")
			if dialogue_system == null:
				dialogue_system = get_node_or_null("../VoiceDialogue")
				if dialogue_system == null:
					# Chercher dans toute la scène
					var root = get_tree().current_scene
					for child in root.get_children():
						if child.has_method("start_dialogue"):
							dialogue_system = child
							print("Found dialogue_system automatically: ", dialogue_system.name)
							break
	
	if dialogue_system == null:
		print("Warning: dialogue_system not found. Please assign it in the inspector or ensure a node with start_dialogue() method exists.")
		return
	
	if dialog != "":
		# Obtenir le noeud d'animation - il est au même niveau que le dialogue
		var animation_node = get_node_or_null("TutorialUI/Lutz Animation")
		
		dialogue_system.start_dialogue(
			dialog,
			animation_node,
			func(): print("Tutorial dialogue ", id, " finished!")
		)
	else:
		print("No tutorial dialogue for level ", id)

func update_current_from_graph() -> void:
	"""
	Recomputes the entire graph and updates the current image display.
	Call this after making changes to the node graph.
	"""
	print("=== update_current_from_graph called ===")
	var computed_image = await compute_updated_image()
	print("Got computed image, updating current display...")
	update_current(computed_image)
	print("=== update_current_from_graph finished ===")

func compute_updated_image() -> Image:
	print("=== Starting compute_updated_image ===")
	
	# First, check if there's a complete path from start to end
	var path_to_end = startNode.get_nodes_from_start_to_end()
	if path_to_end.is_empty():
		print("No complete path from start to end found - returning base image")
		animate_psnr_meter(psnr_start)
		return baseImage
	
	print("Found complete path to end with ", path_to_end.size(), " nodes")
	
	# Dictionary to store computed images for each node (by node ID)
	var computed_images: Dictionary = {}
	
	# Start with the base image for the start node
	computed_images[startNode.id] = baseImage.duplicate()
	print("Added base image for start node ID: ", startNode.id)
	
	# Get all nodes in the graph in topological order
	var all_nodes = get_nodes_in_topological_order()
	print("Found ", all_nodes.size(), " nodes in topological order")
	
	for i in range(all_nodes.size()):
		var node = all_nodes[i]
		print("  Node ", i, ": ID=", node.id, " State=", node.state, " Operator=", node.operatorApplied.name if node.operatorApplied else "none")
	
	if all_nodes.is_empty():
		print("Warning: No nodes found or circular dependency detected")
		animate_psnr_meter(psnr_start)
		return baseImage
	
	# Process each node in topological order
	for current_node in all_nodes:
		print("Processing node ID=", current_node.id, " State=", current_node.state, " Operator=", current_node.operatorApplied.name if current_node.operatorApplied else "none")
		
		# Skip if this is the start node (already has image) or end node (no operation)
		if current_node.state == GraphState.Start:
			print("  Skipping start node")
			continue
		elif current_node.state == GraphState.End:
			print("  Skipping end node")
			continue
			
		# Collect input images from all parent nodes
		var input_images: Array = []
		print("  Node has ", current_node.parents.size(), " parent(s)")
		
		# If we have port connections, use them to order the inputs correctly
		if current_node.port_connections.size() > 0:
			print("  Using port_connections to order inputs")
			# Get the required number of inputs based on operator
			var required_inputs = current_node.operatorApplied.requiredParents
			
			# Build the input array in port order
			for port_index in range(required_inputs):
				if current_node.port_connections.has(port_index):
					var parent = current_node.port_connections[port_index]
					print("    Port ", port_index, ": Parent ID=", parent.id, " computed=", computed_images.has(parent.id))
					if computed_images.has(parent.id):
						input_images.append(computed_images[parent.id])
					else:
						print("Error: Parent node ", parent.id, " at port ", port_index, " has not been computed yet")
						animate_psnr_meter(psnr_start)
						return baseImage
				else:
					print("Error: Port ", port_index, " has no connection")
					animate_psnr_meter(psnr_start)
					return baseImage
		else:
			# Fallback to old behavior if no port connections (shouldn't happen in normal use)
			print("  No port_connections, using parents array order (fallback)")
			for parent in current_node.parents:
				print("    Parent ID=", parent.id, " computed=", computed_images.has(parent.id))
				if computed_images.has(parent.id):
					input_images.append(computed_images[parent.id])
				else:
					print("Error: Parent node ", parent.id, " has not been computed yet")
					animate_psnr_meter(psnr_start)
					return baseImage
		
		# Check if we have the required number of inputs
		print("  Required inputs: ", current_node.operatorApplied.requiredParents, " Got: ", input_images.size())
		if input_images.size() != current_node.operatorApplied.requiredParents:
			print("Error: Node requires ", current_node.operatorApplied.requiredParents, " inputs but got ", input_images.size())
			animate_psnr_meter(psnr_start)
			return baseImage
		
		print("  Applying operator: ", current_node.operatorApplied.name)
		# Apply the operator based on the number of required inputs
		var result_image: Image
		if current_node.operatorApplied.requiredParents == 1:
			# Single input operator
			if current_node.parameters.has("kernel_size"):
				print("    Calling with kernel_size: ", current_node.parameters["kernel_size"])
				result_image = await current_node.operatorApplied.function.call(input_images[0], current_node.parameters["kernel_size"])
			else:
				print("    Calling with single image input")
				result_image = await current_node.operatorApplied.function.call(input_images[0])
		elif current_node.operatorApplied.requiredParents == 2:
			# Two input operator (like difference)
			if current_node.parameters.has("kernel_size"):
				print("    Calling with kernel_size: ", current_node.parameters["kernel_size"])
				result_image = await current_node.operatorApplied.function.call(input_images[0], input_images[1], current_node.parameters["kernel_size"])
			else:
				print("    Calling with two image inputs")
				result_image = await current_node.operatorApplied.function.call(input_images[0], input_images[1])
		else:
			print("Error: Operators with ", current_node.operatorApplied.requiredParents, " inputs not implemented yet")
			animate_psnr_meter(psnr_start)
			return baseImage
		
		# Store the computed image for this node
		computed_images[current_node.id] = result_image
		print("  ✓ Computed image for node ", current_node.id, " (", current_node.operatorApplied.name, ")")
	
	# Find the node that connects to the end node to get the final result
	print("End node has ", endNode.parents.size(), " parent(s)")
	for parent in endNode.parents:
		print("  End node parent ID=", parent.id, " computed=", computed_images.has(parent.id))
		if computed_images.has(parent.id):
			var final_image = computed_images[parent.id]
			# Calculer le PSNR entre l'image finale et l'image cible
			var psnr = PSNR(final_image, targetImage)
			animate_psnr_meter(psnr) # Assuming 50 dB is the max for full meter
			print("✓ PSNR calculé: ", psnr, " dB")
			print("✓ Returning final image from node ", parent.id)
			return final_image
	
	# Fallback: return the last computed image
	print("No end node parent found, using fallback")
	if computed_images.size() > 1: # More than just the start node
		var last_computed_id = computed_images.keys()[-1]
		print("✓ Returning last computed image from node ", last_computed_id)
		var psnr = PSNR(computed_images[last_computed_id], targetImage)
		animate_psnr_meter(psnr)
		return computed_images[last_computed_id]
	
	print("✓ Returning original base image (no processing)")
	animate_psnr_meter(psnr_start)
	return baseImage

func get_nodes_in_topological_order() -> Array:
	"""
	Returns all nodes in the graph in topological order (dependencies first).
	Uses Kahn's algorithm for topological sorting.
	"""
	print("=== get_nodes_in_topological_order ===")
	var all_nodes: Array = []
	var visited: Dictionary = {}
	
	# Collect all nodes in the graph using DFS from start node
	_collect_all_nodes(startNode, all_nodes, visited)
	print("Collected ", all_nodes.size(), " nodes total")
	
	# Calculate in-degree for each node (number of parents)
	var in_degree: Dictionary = {}
	for node in all_nodes:
		in_degree[node.id] = node.parents.size()
		print("  Node ID=", node.id, " in_degree=", node.parents.size(), " children=", node.childs.size())
	
	# Queue for nodes with no dependencies (in-degree = 0)
	var queue: Array = []
	for node in all_nodes:
		if in_degree[node.id] == 0:
			queue.append(node)
	
	var result: Array = []
	
	# Process nodes in topological order
	while not queue.is_empty():
		var current_node = queue.pop_front()
		result.append(current_node)
		
		# For each child of current node, decrease its in-degree
		for child in current_node.childs:
			in_degree[child.id] -= 1
			# If child has no more dependencies, add it to queue
			if in_degree[child.id] == 0:
				queue.append(child)
	
	# Check for circular dependencies
	if result.size() != all_nodes.size():
		print("Warning: Circular dependency detected in graph")
		return []
	
	return result

func _collect_all_nodes(node: PixopGraphNode, all_nodes: Array, visited: Dictionary) -> void:
	"""
	Helper function to collect all nodes in the graph using DFS.
	"""
	if visited.has(node.id):
		return
	
	visited[node.id] = true
	all_nodes.append(node)
	
	# Visit all children
	for child in node.childs:
		_collect_all_nodes(child, all_nodes, visited)

func _ready() -> void:
	# Add this node to the "game" group so other scripts can find it
	add_to_group("game")

	load_level(RequestedLevel.get_level_id())

	# Connect GraphEdit signals
	if graph_edit:
		graph_edit.connection_request.connect(_on_graph_edit_connection_request)
		graph_edit.disconnection_request.connect(_on_graph_edit_disconnection_request)
		graph_edit.connection_drag_started.connect(_on_graph_edit_connection_drag_started)
		graph_edit.connection_drag_ended.connect(_on_graph_edit_connection_drag_ended)
		print("GraphEdit signals connected successfully")
	else:
		print("Warning: GraphEdit node not found")

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("=== Connection request ===")
	print("From: ", from_node, ":", from_port, " -> To: ", to_node, ":", to_port)
	
	# Validate the connection first using GraphEditor's validation function
	if not graph_edit.isConnectionValid(from_node, from_port, to_node, to_port):
		print("✗ Connection validation failed")
		return
	
	print("Available nodes in graph_node_map:")
	for key in graph_node_map.keys():
		print("  ", key, " -> ", graph_node_map[key])
	
	# Get the PixopGraphNode instances
	var from_pixop_node = graph_node_map.get(from_node)
	var to_pixop_node = graph_node_map.get(to_node)

	print("Found PixopGraphNodes - From: ", from_pixop_node != null, " To: ", to_pixop_node != null)
	
	if from_pixop_node and to_pixop_node:
		# Additional validation: check if the node can accept more inputs
		if to_pixop_node.operatorApplied and to_pixop_node.port_connections.size() >= to_pixop_node.operatorApplied.requiredParents:
			print("✗ Target node already has maximum number of inputs (", to_pixop_node.operatorApplied.requiredParents, ")")
			return
		
		# Additional validation: check if this specific port is already connected
		if to_pixop_node.port_connections.has(to_port):
			print("✗ Target port ", to_port, " is already connected")
			return
		
		print("Found both PixopGraphNodes - updating connections")
		# Update the PixopGraphNode connections with port information
		from_pixop_node.add_child(to_pixop_node, to_port)
		
		# Allow the GraphEdit connection
		graph_edit.connect_node(from_node, from_port, to_node, to_port)
		
		spawn_connection_particles(from_node, to_node)
		
		print("✓ Successfully connected: ", from_node, " -> ", to_node, " (port ", to_port, ")")
		print("  From node children count: ", from_pixop_node.childs.size())
		print("  To node parents count: ", to_pixop_node.parents.size())
		print("  To node port_connections: ", to_pixop_node.port_connections)
		
		# Recompute the graph and update display
		print("Calling update_current_from_graph()...")
		update_current_from_graph()
	else:
		print("✗ Connection failed - missing PixopGraphNodes:")
		print("  From node (", from_node, "): ", "Found" if from_pixop_node else "Not found")
		print("  To node (", to_node, "): ", "Found" if to_pixop_node else "Not found")

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("=== DISCONNECTION REQUEST ===")
	print("Disconnection request: ", from_node, ":", from_port, " -> ", to_node, ":", to_port)
	
	print("Available nodes in graph_node_map:")
	for key in graph_node_map.keys():
		print("  ", key, " -> ", graph_node_map[key])
	
	# Get the PixopGraphNode instances using the same method as connection
	var from_pixop_node = graph_node_map.get(from_node)
	var to_pixop_node = graph_node_map.get(to_node)
	
	print("Found PixopGraphNodes - From: ", from_pixop_node != null, " To: ", to_pixop_node != null)
	
	if from_pixop_node and to_pixop_node:
		print("Found both PixopGraphNodes - updating disconnections")
		# Update the PixopGraphNode connections with port information
		from_pixop_node.remove_child(to_pixop_node, to_port)
		
		# Allow the GraphEdit disconnection
		graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
		
		
		print("✓ Successfully disconnected: ", from_node, " -> ", to_node, " (port ", to_port, ")")
		print("  From node children count: ", from_pixop_node.childs.size())
		print("  To node parents count: ", to_pixop_node.parents.size())
		print("  To node port_connections: ", to_pixop_node.port_connections)
		
		# Recompute the graph and update display
		print("Calling update_current_from_graph() after disconnection...")
		update_current_from_graph()
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
	elif operator == "seuil":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, seuil_otsu_operator, {})
	elif operator == "difference":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, difference_operator, {})
	elif operator == "negatif":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, negatif_operator, {})
	elif operator == "expdyn":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, expansion_dynamique_operator, {})
	elif operator == "blur_background":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, flou_fond_operator, {"kernel_size": 5})
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
