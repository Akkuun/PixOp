extends GraphEdit

func _ready():
	# Make sure the node can process input events
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	# Set minimap visibility if needed
	minimap_enabled = true
	# Connect signals

	
	# Print confirmation that the graph edit is ready
	print("GraphEdit initialized and ready for interaction")

func _on_node_moved():
	print("Node moved - GraphEdit is responding to interaction")
