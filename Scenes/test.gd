extends GraphEdit

func _ready():
	# Créons un node Blur
	var blur_node = GraphNode.new()
	blur_node.title = "Blur"
	blur_node.offset = Vector2(100, 100) # Position dans la grille
	
	# Ajouter des slots (input/output)
	# set_slot(idx, enable_left, type_left, color_left, enable_right, type_right, color_right, custom)
	blur_node.set_slot(0, true,  0, Color.BLUE, true, 0, Color.GREEN) # entrée/sortie sur la même ligne
	blur_node.set_slot(1, true,  0, Color.BLUE, false, 0, Color.GREEN) # juste une entrée
	blur_node.set_slot(2, false, 0, Color.BLUE, true, 0, Color.GREEN)  # juste une sortie
	
	add_child(blur_node)

	# Créons un node Resize
	var resize_node = GraphNode.new()
	resize_node.title = "Resize"
	resize_node.offset = Vector2(400, 200)
	resize_node.set_slot(0, true, 0, Color.BLUE, true, 0, Color.GREEN)
	add_child(resize_node)

	# Connectons-les
	connect_node(blur_node.name, 2, resize_node.name, 0)
