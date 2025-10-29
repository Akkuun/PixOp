extends Button

@export var prefabNode: PackedScene
@export var graph_edit: GraphEdit
@export var addNodeSound: AudioStream

var audio_player_addNode: AudioStreamPlayer

func _ready():
	pressed.connect(_on_button_pressed)
	audio_player_addNode = AudioStreamPlayer.new()
	audio_player_addNode.stream = addNodeSound
	audio_player_addNode.bus = "Resume"
	audio_player_addNode.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player_addNode.volume_db = -27.5
	add_child(audio_player_addNode)

func _on_button_pressed():
	if prefabNode == null or graph_edit == null:
		push_error("node_scene ou graph_edit non assigné")
		return
	
	var new_node: GraphNode = prefabNode.instantiate()
	
	# Positionner au centre du GraphEdit
	var offset = graph_edit.scroll_offset + graph_edit.size / 2
	new_node.position_offset = offset / graph_edit.zoom

	audio_player_addNode.play()
	
	graph_edit.add_child(new_node, true)
	
	# Use call_deferred to get the final name after GraphEdit processes it
	call_deferred("_register_node_after_add", new_node)

func _register_node_after_add(node: GraphNode):
	# Now get the actual final name assigned by Godot (after potential renaming)
	var final_node_name = node.name
	print("Final GraphNode name in GraphEdit: ", final_node_name)
	
	# Get the game script to access graph_node_map
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("register_graph_node"):
		var metadata_operator: String = node.get_meta("operator")
		if metadata_operator:
			# Update the graph_node_map with node_name -> pixop_node
			game.register_graph_node(final_node_name, metadata_operator)
		else:
			print("Warning: Node's metadata 'operator' is null")
	else:
		print("Warning: Could not find game node in 'game' group")
