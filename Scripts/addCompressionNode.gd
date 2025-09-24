extends Button

@export var node_scene: PackedScene
@export var graph_edit: GraphEdit

func _ready():
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if node_scene == null or graph_edit == null:
		push_error("node_scene ou graph_edit non assigné")
		return
	
	var new_node: GraphNode = node_scene.instantiate()
	
	# Positionner au centre du GraphEdit
	var offset = graph_edit.scroll_offset + graph_edit.size / 2
	new_node.position_offset = offset / graph_edit.zoom
	
	graph_edit.add_child(new_node)
