extends GraphEdit


@export var connectionSound: AudioStream 
@export var clearSound : AudioStream

@export var startNode : GraphNode
@export var endNode : GraphNode

var audio_player_connection: AudioStreamPlayer
var audio_player_clear : AudioStreamPlayer



func _ready():
	# Connexions pour créer / supprimer les liens
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)

	audio_player_connection = AudioStreamPlayer.new()
	audio_player_clear = AudioStreamPlayer.new()
	audio_player_connection.stream = connectionSound
	audio_player_clear.stream = clearSound
	add_child(audio_player_connection)
	add_child(audio_player_clear)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	if isConnectionValid(from_node, from_port, to_node, to_port):
		connect_node(from_node, from_port, to_node, to_port)
		audio_player_connection.play()


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

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
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
			audio_player_clear.play()
