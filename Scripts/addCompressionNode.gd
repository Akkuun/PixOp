extends Button

# La scène que tu veux ajouter (doit être un GraphNode)
@export var node_scene: PackedScene

# Référence vers le GraphEdit (à glisser depuis l'éditeur si possible)
@export var graph_edit: GraphEdit

func _ready():
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if node_scene == null:
		push_error("⚠️ node_scene n'est pas assigné !")
		return
	if graph_edit == null:
		push_error("⚠️ graph_edit n'est pas assigné !")
		return
	
	# Instancier le GraphNode
	var new_node: GraphNode = node_scene.instantiate()
	
	# Définir la position (au centre du GraphEdit)
	var offset = graph_edit.scroll_offset + graph_edit.size / 2.0
	new_node.position_offset = offset / graph_edit.zoom
	
	# Ajouter le nœud dans le GraphEdit
	graph_edit.add_child(new_node)
