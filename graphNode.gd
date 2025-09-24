extends GraphNode

func _ready():
	# Crée un port d'entrée gauche et un port de sortie droite
	set_slot(0, true, 0, Color.RED, true, 0, Color.GREEN)
	title = "Node"
