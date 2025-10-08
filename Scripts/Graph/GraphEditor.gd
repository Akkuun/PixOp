extends GraphEdit




func _ready():
	# Connexions pour créer / supprimer les liens
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	if isConnectionValid(from_node, from_port, to_node, to_port):
		connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	disconnect_node(from_node, from_port, to_node, to_port)


func isConnectionValid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	if from_node == to_node:  # Si le noeud de départ est le même que le noeud d'arrivée donc on tente une connexion sur sa propre entrée, on refuse la connexion
		return false
	# On empeche de connecter plusieurs fois une entrée
	for conn in get_connection_list():
		if conn["to_node"] == to_node and conn["to_port"] == to_port:
			return false
	return true
