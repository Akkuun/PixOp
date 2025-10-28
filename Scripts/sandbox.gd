extends "res://Scripts/image_lib_wrapper.gd"

const PARTICLE_SCENE = preload("res://prefab/node_particles.tscn")

var images_folder = "res://Images"

var startNode: PixopGraphNode
var endNode: PixopGraphNode

var definedW = 192.0
var definedH = 192.0

var baseImage: Image
var editedImage: Image

var dialog: String = ""

var dialogue_system: Control  # Référence au système de dialogue

var selected_node: PixopGraphNode  # Currently selected node for preview
var cached_image: Image  # Cached computed image to prevent flashes

# Dictionary to map GraphNode names to their PixopGraphNode instances
@export var graph_node_map: Dictionary = {}

@export var current: Sprite2D
@export var graph_edit : GraphEdit
@export var main_theme_player : AudioStreamPlayer

@export var eye: Sprite2D

func _on_load_new_button_pressed() -> void:
	var file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	file_dialog.filters = ["*.png ; PNG Image", "*.jpg ; JPEG Image", "*.jpeg ; JPEG Image", "*.bmp ; BMP Image", "*.tga ; TGA Image", "*.webp ; WEBP Image", "*.gif ; GIF Image"]
	add_child(file_dialog)

	file_dialog.popup_centered(Vector2i(800, 600))

	# Wait for file selection
	var selected_file = await file_dialog.file_selected

	print("File dialog closed, selected file: ", selected_file)
	file_dialog.queue_free()
	if selected_file != "":
		print("Selected file: ", selected_file)

		var image = Image.new()
		var err = image.load(selected_file)
		if err == OK:
			baseImage = image	
			update_current(baseImage)
			update_current_from_graph()
		else:
			push_error("Failed to load image from path: " + selected_file)
	else:
		print("No file selected")


func _on_save_image_button_pressed() -> void:
	var file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	file_dialog.filters = ["*.png", "*.jpg", "*.jpeg"]
	file_dialog.title = "Save Image"
	file_dialog.current_file = "pixop.png"

	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))
	var save_path = await file_dialog.file_selected
	file_dialog.queue_free()

	if save_path != "":
		print("Selected save path: ", save_path)
		var image = editedImage.duplicate()
		var err = image.save_png(save_path)
		if err == OK:
			print("Image saved successfully!")
		else:
			push_error("Failed to save image to path: " + save_path)
	else:
		print("No save path selected")

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

func show_tutorial_dialogue() -> void:
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
			func(): print("Tutorial dialogue finished!")
		)
	else:
		print("No tutorial dialogue")

func load_level() -> void:
	startNode = PixopGraphNode.new(GraphState.Start, null, {}, [], "Start_node")
	endNode = PixopGraphNode.new(GraphState.End, end_operator, {}, [], "Final_node")
	graph_node_map.clear()
	graph_node_map["Start_node"] = startNode
	graph_node_map["Final_node"] = endNode
	var texCurrent := load(images_folder + "/placeholder.jpg")
	editedImage = texCurrent.get_image()
	baseImage = texCurrent.get_image()
	cached_image = baseImage.duplicate()
	update_current(baseImage)

	var level_data = FileAccess.get_file_as_string("res://Levels/levels_data.json")
	
	var json = JSON.new()
	var error = json.parse(level_data)
	if error != OK:
		push_error("Failed to parse levels_data.json: " + str(error))
		return
	var level_data_dict = json.data
	print("Level data dict: ", level_data_dict)

	dialog = level_data_dict.get("sandbox").get("dialog")

	show_tutorial_dialogue()

func update_current(image: Image) -> void:
	var texture := ImageTexture.create_from_image(image)
	current.texture = texture
	var imgW = texture.get_width()
	var imgH = texture.get_height()
	current.scale = Vector2(definedW / imgW, definedH / imgH)

func update_current_from_graph() -> void:
	"""
	Recomputes the entire graph and updates the current image display.
	Call this after making changes to the node graph.
	"""
	print("=== update_current_from_graph called ===")
	var computed_image = await compute_updated_image(selected_node)
	cached_image = computed_image
	editedImage = computed_image
	update_current(cached_image)
	print("=== update_current_from_graph finished ===")

func compute_updated_image(target_node: PixopGraphNode = null) -> Image:
	if target_node == null:
		target_node = endNode
	print("=== Starting compute_updated_image to target: ", target_node.id, " ===")
	
	# First, check if there's a complete path from start to target
	var path_to_target = startNode.get_nodes_from_start_to_target(target_node)
	if path_to_target.is_empty():
		print("No complete path from start to target found - returning base image")
		return baseImage
	
	print("Found complete path to target with ", path_to_target.size(), " nodes")
	
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
					var conn = current_node.port_connections[port_index]
					var parent = conn["parent"]
					var output_port = conn["output_port"]
					print("    Port ", port_index, ": Parent ID=", parent.id, " output_port=", output_port, " computed=", computed_images.has(parent.id))
					if computed_images.has(parent.id):
						var parent_result = computed_images[parent.id]
						if parent_result is Dictionary:
							var keys = ["Y", "Cb", "Cr"]
							if output_port < keys.size():
								input_images.append(parent_result[keys[output_port]])
							else:
								print("Error: Invalid output_port ", output_port)
								return baseImage
						else:
							input_images.append(parent_result)
					else:
						print("Error: Parent node ", parent.id, " has not been computed yet")
						return baseImage
				else:
					print("Error: Port ", port_index, " has no connection")
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
					return baseImage
		
		# Check if we have the required number of inputs
		print("  Required inputs: ", current_node.operatorApplied.requiredParents, " Got: ", input_images.size())
		if input_images.size() != current_node.operatorApplied.requiredParents:
			print("Error: Node requires ", current_node.operatorApplied.requiredParents, " inputs but got ", input_images.size())
			return baseImage
		
		print("  Applying operator: ", current_node.operatorApplied.name)
		# Apply the operator based on the number of required inputs
		var result_image
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
		elif current_node.operatorApplied.requiredParents == 3:
			# Three input operator (ycbcr_to_rgb)
			print("    Calling with three image inputs")
			result_image = await current_node.operatorApplied.function.call(input_images[0], input_images[1], input_images[2])
		else:
			print("Error: Operators with ", current_node.operatorApplied.requiredParents, " inputs not implemented yet")
			return baseImage
		
		# Store the computed image for this node
		computed_images[current_node.id] = result_image
		print("  ✓ Computed image for node ", current_node.id, " (", current_node.operatorApplied.name, ")")
	
	# Get the result based on the target node
	var final_result: Image
	if target_node == startNode:
		final_result = baseImage
	elif target_node.state == GraphState.End:
		# For end node, find the parent image
		for parent in target_node.parents:
			if computed_images.has(parent.id):
				final_result = computed_images[parent.id]
				break
		if not final_result:
			final_result = baseImage
	else:
		# For middle nodes, return the computed image of the target node itself
		if computed_images.has(target_node.id):
			var target_result = computed_images[target_node.id]
			if target_result is Dictionary:
				# Special case for rgb_to_ycbcr: visualize
				if target_node.operatorApplied == rgb_to_ycbcr_operator:
					var input_img = computed_images[target_node.parents[0].id]
					final_result = await ycbcr_visualize(input_img)
				else:
					print("Error: Cannot display multi-output node result")
					final_result = baseImage
			else:
				final_result = target_result
		else:
			final_result = baseImage
	
	print("✓ Returning image for target node ", target_node.id, " (", target_node.operatorApplied.name if target_node.operatorApplied else "none", ")")
	return final_result

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

func _place_eye_on_graphnode_name(node_name: StringName) -> void:
	if not eye or not graph_edit:
		return
	var graph_node = graph_edit.get_node_or_null(str(node_name))
	if not graph_node:
		eye.hide()
		return
	if eye.get_parent():
		eye.get_parent().remove_child(eye)
	graph_node.add_child(eye)
	eye.position = Vector2(16, -1)
	eye.show()

func _ready() -> void:
	# Add this node to the "game" group so other scripts can find it
	add_to_group("game")
	
	load_level()

	# Set initial selection to start node and position eye from the right
	selected_node = startNode
	if eye:
		_place_eye_on_graphnode_name(startNode.name)

	# Connect GraphEdit signals
	if graph_edit:
		graph_edit.connection_request.connect(_on_graph_edit_connection_request)
		graph_edit.disconnection_request.connect(_on_graph_edit_disconnection_request)
		graph_edit.connection_drag_started.connect(_on_graph_edit_connection_drag_started)
		graph_edit.connection_drag_ended.connect(_on_graph_edit_connection_drag_ended)
		graph_edit.node_selected.connect(_on_node_selected)
		graph_edit.node_deleted.connect(_on_node_deleted)
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
		from_pixop_node.add_child(to_pixop_node, to_port, from_port)
		
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
		from_pixop_node.remove_child(to_pixop_node, to_port, from_port)
		
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

func _on_node_selected(node: Node) -> void:
	# Remove eye from previous selected node
	if selected_node and eye:
		var old_graph_node = graph_edit.get_node(selected_node.name)
		if old_graph_node and eye.get_parent() == old_graph_node:
			old_graph_node.remove_child(eye)
			eye.hide()
	
	selected_node = graph_node_map.get(node.name)
	print("Selected node: ", str(selected_node.id) if selected_node else "none")
	
	# Add eye to new selected node
	if selected_node and eye:
		# Use helper to position the eye from the right on the selected GraphNode
		_place_eye_on_graphnode_name(selected_node.name)
	else:
		# No selection, hide eye
		if eye:
			if eye.get_parent():
				eye.get_parent().remove_child(eye)
			eye.hide()
	
	update_current_from_graph()

func _on_node_deleted(node_name: StringName) -> void:
	var deleted_node = graph_node_map.get(node_name)
	if deleted_node == selected_node:
		selected_node = null
		print("Selected node was deleted, resetting selection")
		# Remove eye if it was on the deleted node
		if eye and eye.get_parent() and eye.get_parent().name == node_name:
			eye.get_parent().remove_child(eye)
			eye.hide()
	graph_node_map.erase(node_name)
	print("Removed deleted node from graph_node_map: ", node_name)

# Helper function to register GraphNodes (no longer needed with direct access method)
func register_graph_node(graph_node_name: String, operator: String) -> void:
	var new_pixop_node = null
	# Toby fox my love
	if operator == "start":
		new_pixop_node = startNode
	elif operator == "final":
		new_pixop_node = endNode
	if operator == "blur":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, flou_operator, {"kernel_size": 5}, [], graph_node_name)
	elif operator == "dilatation":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, dilatation_operator, {"kernel_size": 5}, [], graph_node_name)
	elif operator == "erosion":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, erosion_operator, {"kernel_size": 5}, [], graph_node_name)
	elif operator == "seuil":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, seuil_otsu_operator, {}, [], graph_node_name)
	elif operator == "difference":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, difference_operator, {}, [], graph_node_name)
	elif operator == "negatif":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, negatif_operator, {}, [], graph_node_name)
	elif operator == "expdyn":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, expansion_dynamique_operator, {}, [], graph_node_name)
	elif operator == "blur_background":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, flou_fond_operator, {"kernel_size": 5}, [], graph_node_name)
	elif operator == "rgb_to_ycbcr":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, rgb_to_ycbcr_operator, {}, [], graph_node_name)
	elif operator == "ycbcr_to_rgb":
		new_pixop_node = PixopGraphNode.new(GraphState.Middle, ycbcr_to_rgb_operator, {}, [], graph_node_name)
	if new_pixop_node == null:
		print("Warning: Could not create PixopGraphNode for operator '", operator, "'")
		return
	graph_node_map[graph_node_name] = new_pixop_node
	print("Registered GraphNode '", graph_node_name, "' with operator '", operator, "'")
