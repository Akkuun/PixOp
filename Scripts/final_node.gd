extends GraphNode

func _ready():
	# slot 0 : entrée (gauche) et sortie (droite)
	# set_slot(index, enable_left, type_left, color_left, enable_right, type_right, color_right)
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
