extends Control


@onready var voicebox: ACVoiceBox = $ACVoicebox
@onready var label: Label = $Label
@onready var lutz_animation: Node2D = get_node("../")  # Reference to the Lutz Animation node


@onready var conversation = [
	"Hey look, I've made this Animal Crossing style conversation player in Godot!"
]

var conversation_index: int = 0


func _ready():
	voicebox.connect("characters_sounded", _on_voicebox_characters_sounded)
	voicebox.connect("finished_phrase", _on_voicebox_finished_phrase)
	# Si conversation est une string, la convertir en liste
	if typeof(conversation) == TYPE_STRING:
		conversation = [conversation]
	play_next_in_conversation()


func _on_voicebox_characters_sounded(characters: String):
	label.text += characters


func _on_voicebox_finished_phrase():
	# Arrêter l'animation quand le personnage finit de parler
	lutz_animation.stop_animation()
	
	conversation_index += 1
	if conversation_index < conversation.size():
		play_next_in_conversation()
	

func play_next_in_conversation():
	# Si conversation est une string, la convertir en liste
	if typeof(conversation) == TYPE_STRING:
		conversation = [conversation]
	if conversation_index < conversation.size():
		label.text = ""  # Clear previous text
		var dialogue_text = conversation[conversation_index]
		# Démarrer l'animation avant de commencer à parler
		lutz_animation.start_animation()
		voicebox.play_string(dialogue_text)
