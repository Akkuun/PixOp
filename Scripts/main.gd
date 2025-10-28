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
@export var main_theme_player : AudioStreamPlayer

@export var eye: Sprite2D

var dialogue_system: Control  # Référence au système de dialogue
@export var level_complete_popup_scene: PackedScene

var _current_popup: Node = null


var selected_node: PixopGraphNode  # Currently selected node for preview
var cached_image: Image  # Cached computed image to prevent flashes

func animate_psnr_meter(value: float, end: bool = false) -> void:
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
		# if selected node is end_node, play the popup
		if end || selected_node.state == GraphState.End:
			tween.finished.connect(func():
				_show_level_complete_popup(value)
			, CONNECT_ONE_SHOT)

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
	animate_psnr_meter(0.0) # Reset PSNR meter at level start
	
	# Clear the graph before loading new level
	_clear_graph()
	
	levelId = id
	startNode = PixopGraphNode.new(GraphState.Start, null, {}, [], "Start_node")
	endNode = PixopGraphNode.new(GraphState.End, end_operator, {}, [], "Final_node")
	graph_node_map.clear()
	graph_node_map["Start_node"] = startNode
	graph_node_map["Final_node"] = endNode
	var level_path = images_folder + "/" + str(id)
	var texCurrent := load(level_path + "/current.png")
	var texTarget := load(level_path + "/target.png")
	baseImage = texCurrent.get_image()
	targetImage = texTarget.get_image()

	cached_image = baseImage.duplicate()

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

func _clear_graph() -> void:
	"""
	Clears all graph nodes from the GraphEdit except Start and Final nodes.
	"""
	if not graph_edit:
		return
	
	print("=== Clearing graph ===")
	
	# Get all GraphNode children
	var nodes_to_remove = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			# Keep Start_node and Final_node
			if child.name != "Start_node" and child.name != "Final_node":
				nodes_to_remove.append(child)
	
	# Remove all GraphNodes except Start and Final
	for node in nodes_to_remove:
		print("Removing node: ", node.name)
		graph_edit.remove_child(node)
		node.queue_free()
	
	# Clear all connections
	graph_edit.clear_connections()
	
	print("✓ Graph cleared: ", nodes_to_remove.size(), " nodes removed (kept Start_node and Final_node)")

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
	var computed_image = await compute_updated_image(selected_node)
	cached_image = computed_image
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
		animate_psnr_meter(psnr_start)
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
								animate_psnr_meter(psnr_start)
								return baseImage
						else:
							input_images.append(parent_result)
					else:
						print("Error: Parent node ", parent.id, " has not been computed yet")
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
			animate_psnr_meter(psnr_start)
			return baseImage
		
		# Store the computed image for this node
		computed_images[current_node.id] = result_image
		print("  ✓ Computed image for node ", current_node.id, " (", current_node.operatorApplied.name, ")")
	
	# Get the result based on the target node
	var final_result: Image
	if target_node == startNode:
		final_result = baseImage
		animate_psnr_meter(psnr_start)
	elif target_node.state == GraphState.End:
		# For end node, find the parent image
		for parent in target_node.parents:
			if computed_images.has(parent.id):
				final_result = computed_images[parent.id]
				var psnr = PSNR(final_result, targetImage)
				animate_psnr_meter(psnr)
				break
		if not final_result:
			final_result = baseImage
			animate_psnr_meter(psnr_start)
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
			var psnr = PSNR(final_result, targetImage)
			animate_psnr_meter(psnr)
		else:
			final_result = baseImage
			animate_psnr_meter(psnr_start)
	
	print("✓ Returning image for target node ", target_node.id, " (", target_node.operatorApplied.name if target_node.operatorApplied else "none", ")")
	return final_result

func _show_level_complete_popup(psnr_value: float) -> void:
	# Instantiate popup scene (use exported PackedScene if set, otherwise load default prefab)
	var popup_scene = level_complete_popup_scene if level_complete_popup_scene else load("res://prefab/pop-up_end.tscn")
	if not popup_scene:
		push_warning("Level complete popup scene not found")
		return

	var popup = popup_scene.instantiate()
	# Add to current scene so it displays above
	var root = get_tree().current_scene
	if root:
		# Prefer an existing UI CanvasLayer so popup is above other UI
		var ui_layer = root.get_node_or_null("DialogButtonsLayer")
		if ui_layer and ui_layer is CanvasLayer:
			ui_layer.add_child(popup)
		else:
			root.add_child(popup)
	else:
		add_child(popup)
	
	# place in center of screen the popup
	# by moving the node2D of the popup
	# The popup root is already the PopUpEnd Node2D
	var popup_node2d = popup

	print("J'ai trouvé le popup_node2d: ", popup_node2d)
	
	# Center the popup on screen
	var viewport_size = get_viewport().get_visible_rect().size
	var panel = popup_node2d.get_node_or_null("Panel")
	if panel:
		var panel_size = panel.size
		popup_node2d.position = Vector2(
			(viewport_size.x - panel_size.x) / 2.0,
			(viewport_size.y - panel_size.y) / 2.0
		)
		print("Popup centered at position: ", popup_node2d.position)

	# Keep reference so handlers can remove it
	_current_popup = popup

	# Pause the dialogue system 
	if dialogue_system and dialogue_system.has_method("pause_dialogue"):
		dialogue_system.pause_dialogue()

	# Show message
	var message = "PSNR: " + str(psnr_value) + " dB\nGoal: " + str(psnr_goal) + " dB"
	var lbl = popup.get_node_or_null("Panel/Label")
	if lbl:
		lbl.text = message
	else:
		print("Warning: Could not find Panel/Label in popup")

	# Connect signals if present
	if popup.has_signal("menu_pressed"):
		popup.connect("menu_pressed", Callable(self, "_on_popup_menu"))
		print("✓ Connected menu_pressed signal")
	else:
		print("✗ menu_pressed signal not found on popup")
		
	if popup.has_signal("retry_pressed"):
		popup.connect("retry_pressed", Callable(self, "_on_popup_retry"))
		print("✓ Connected retry_pressed signal")
	else:
		print("✗ retry_pressed signal not found on popup")
		
	if popup.has_signal("next_pressed"):
		popup.connect("next_pressed", Callable(self, "_on_popup_next"))
		print("✓ Connected next_pressed signal")
	else:
		print("✗ next_pressed signal not found on popup")

func _on_popup_menu() -> void:
	print("=== MAIN: _on_popup_menu called ===")
	# Continue the dialogue before going to menu
	if dialogue_system and dialogue_system.has_method("resume_dialogue"):
		dialogue_system.resume_dialogue()
	
	# Close and go to menu scene
	if _current_popup:
		_current_popup.queue_free()
		_current_popup = null

	# Change to menu scene if exists
	var menu_scene_path = "res://Scenes/menu.tscn"
	if FileAccess.file_exists(menu_scene_path):
		print("=== MAIN: Changing to menu scene ===")
		get_tree().change_scene_to_file(menu_scene_path)
	else:
		print("Menu scene not found: ", menu_scene_path)

func _on_popup_retry() -> void:
	print("=== MAIN: _on_popup_retry called ===")
	# Continue the dialogue before reloading
	if dialogue_system and dialogue_system.has_method("resume_dialogue"):
		dialogue_system.resume_dialogue()
	_close_popup_and_load_level(levelId)

func _on_popup_next() -> void:
	print("=== MAIN: _on_popup_next called ===")
	# Continue the dialogue before going to the next level
	if dialogue_system and dialogue_system.has_method("resume_dialogue"):
		dialogue_system.resume_dialogue()
	_close_popup_and_load_level(levelId + 1)

func _close_popup_and_load_level(level_id: int) -> void:
	print("=== MAIN: Loading level ", level_id, " ===")
	# Close popup
	if _current_popup:
		_current_popup.queue_free()
		_current_popup = null
	
	# Load the requested level
	load_level(level_id)


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

	load_level(RequestedLevel.get_level_id())

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
