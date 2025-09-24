extends GraphNode

func _ready():
	# slot 0 : entrée (gauche) et sortie (droite)
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)
