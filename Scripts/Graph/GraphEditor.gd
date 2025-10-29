extends GraphEdit

signal node_deleted(node_name: StringName)

@export var connectionSound: AudioStream 
@export var clearSound : AudioStream

@export var startNode : GraphNode
@export var endNode : GraphNode

var audio_player_connection: AudioStreamPlayer
var audio_player_clear : AudioStreamPlayer



func _ready():
	# Les connexions sont maintenant gérées par game.gd qui appelle isConnectionValid()
	# On ne connecte plus les signaux ici pour éviter les doublons
	# connection_request.connect(_on_connection_request)
	# disconnection_request.connect(_on_disconnection_request)

	audio_player_connection = AudioStreamPlayer.new()
	audio_player_clear = AudioStreamPlayer.new()
	audio_player_connection.stream = connectionSound
	audio_player_clear.stream = clearSound
	audio_player_connection.bus = "Resume"
	audio_player_clear.bus = "Resume"
	audio_player_connection.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player_clear.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player_connection.volume_db = -27.5
	audio_player_clear.volume_db = -27.5
	add_child(audio_player_connection)
	add_child(audio_player_clear)

# Ces fonctions ne sont plus utilisées car game.gd gère les connexions
# mais on les garde au cas où
#func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
#	if isConnectionValid(from_node, from_port, to_node, to_port):
#		connect_node(from_node, from_port, to_node, to_port)
#		audio_player_connection.play()
#
#
#func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
#	disconnect_node(from_node, from_port, to_node, to_port)


# Cette fonction est appelée par game.gd pour valider les connexions
func isConnectionValid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	# Empêcher la connexion d'un node sur lui-même (sortie vers sa propre entrée)
	if from_node == to_node:
		print("Cannot connect a node to itself")
		return false
	
	# Vérifier qu'il n'existe pas déjà une connexion dans le sens inverse (empêcher les boucles)
	for conn in get_connection_list():
		if conn["from_node"] == to_node and conn["to_node"] == from_node:
			print("Cannot create reverse connection - would create a loop")
			return false
	
	# Empêcher de connecter plus d'une sortie au node de end
	if to_node == endNode.name:
		for conn in get_connection_list():
			if conn["to_node"] == to_node:
				print("End node already has a connection - only one connection allowed")
				return false
	
	# Empêcher de connecter plusieurs fois la même entrée
	for conn in get_connection_list():
		if conn["to_node"] == to_node and conn["to_port"] == to_port:
			print("This input port is already connected")
			return false
	
	# Empêcher de connecter plusieurs fois la même sortie au même node
	for conn in get_connection_list():
		if conn["from_node"] == from_node and conn["from_port"] == from_port and conn["to_node"] == to_node:
			print("This output is already connected to this node")
			return false
	
	return true

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		# Supprimer les nodes sélectionnés avec la touche delete
		if event.keycode == KEY_DELETE or event.keycode == 4194308:
			for child in get_children():
				if child is GraphNode and child.selected:
					# on skip pour les nodes start et end
					if child == startNode or child == endNode:
						continue
					var node_name = child.name
					# Déconnecte toutes les connexions du node sauf pour le node de start et le node de end
					for conn in get_connection_list():
						if conn["from_node"] == node_name or conn["to_node"] == node_name:
							disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
							emit_signal("disconnection_request", conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
					# Supprime le node
					child.queue_free()
					emit_signal("node_deleted", node_name)
			audio_player_clear.play()
			
