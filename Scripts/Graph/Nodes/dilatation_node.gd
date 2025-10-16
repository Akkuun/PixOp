extends GraphNode

func _ready():
	# Configuration des slots : 1 entrée à gauche, 1 sortie à droite
	# set_slot(index, enable_left, type_left, color_left, enable_right, type_right, color_right)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
