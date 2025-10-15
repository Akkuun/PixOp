extends Control


@onready var voicebox: ACVoiceBox = $ACVoicebox
@onready var label: Label = $Label
@onready var lutz_animation: Node2D = get_node("../")  # Reference to the Lutz Animation node


var conversation = []
var conversation_index: int = 0
var on_dialogue_finished_callback: Callable


func _ready():
	voicebox.connect("characters_sounded", _on_voicebox_characters_sounded)
	voicebox.connect("finished_phrase", _on_voicebox_finished_phrase)


# Fonction principale pour démarrer un dialogue
# @param dialogue: String ou Array de Strings contenant le(s) texte(s) à afficher
# @param animation_node: Node2D optionnel pour l'animation du personnage (si null, pas d'animation)
# @param on_finished: Callable optionnel appelé quand tout le dialogue est terminé
func start_dialogue(dialogue, animation_node: Node2D = null, on_finished: Callable = Callable()):
	# Réinitialiser l'index
	conversation_index = 0
	
	# Convertir le dialogue en array si c'est une string
	if typeof(dialogue) == TYPE_STRING:
		conversation = [dialogue]
	else:
		conversation = dialogue
	
	# Mettre à jour le noeud d'animation si fourni
	if animation_node != null:
		lutz_animation = animation_node
	
	# Stocker le callback
	on_dialogue_finished_callback = on_finished
	
	# Démarrer le dialogue
	play_next_in_conversation()


func _on_voicebox_characters_sounded(characters: String):
	label.text += characters


func _on_voicebox_finished_phrase():
	# Arrêter l'animation quand le personnage finit de parler
	if lutz_animation != null:
		lutz_animation.stop_animation()
	
	conversation_index += 1
	if conversation_index < conversation.size():
		play_next_in_conversation()
	else:
		# Tout le dialogue est terminé, appeler le callback si défini
		if on_dialogue_finished_callback.is_valid():
			on_dialogue_finished_callback.call()
	

func play_next_in_conversation():
	if conversation_index < conversation.size():
		label.text = ""  # Clear previous text
		var dialogue_text = conversation[conversation_index]
		# Démarrer l'animation avant de commencer à parler
		if lutz_animation != null:
			lutz_animation.start_animation()
		voicebox.play_string(dialogue_text)
