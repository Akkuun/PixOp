extends Control


@onready var voicebox: ACVoiceBox = $ACVoicebox
@onready var label: Label = $Label
@onready var lutz_animation: Node2D = get_node("../")  # Reference to the Lutz Animation node

# Boutons de navigation (DialogButtonsLayer)
var prev_button: Button
var next_button: Button


var conversation = []
var conversation_index: int = 0
var on_dialogue_finished_callback: Callable

# Variables pour la pagination
var current_page: int = 0
var pages: Array = []  # Chaque page contient les lignes de texte
var lines_per_page: int = 3  # Nombre de lignes par page
var current_full_text: String = ""  # Le texte complet en cours


func _ready():
	voicebox.connect("characters_sounded", _on_voicebox_characters_sounded)
	voicebox.connect("finished_phrase", _on_voicebox_finished_phrase)
	
	# Connecter les boutons si ils existent
	# Les boutons sont dans un CanvasLayer racine; on les cherche dynamiquement
	var root = get_tree().current_scene
	if root:
		prev_button = root.get_node_or_null("DialogButtonsLayer/PrevButton")
		next_button = root.get_node_or_null("DialogButtonsLayer/NextButton")

	if prev_button:
		prev_button.pressed.connect(_on_prev_page)
	if next_button:
		next_button.pressed.connect(_on_next_page)
	
	_update_navigation_buttons()


func _create_navigation_buttons():
	"""
	Crée les boutons de navigation pour parcourir les pages
	"""
	# Cette fonction n'est plus nécessaire car les boutons sont créés dans la scène
	pass


func _update_navigation_buttons():
	"""
	Met à jour l'état des boutons de navigation
	"""
	if prev_button:
		prev_button.disabled = current_page <= 0
		prev_button.visible = pages.size() > 1
	
	if next_button:
		next_button.disabled = current_page >= pages.size() - 1
		next_button.visible = pages.size() > 1


func _on_prev_page():
	"""
	Affiche la page précédente
	"""
	if current_page > 0:
		current_page -= 1
		_display_current_page()


func _on_next_page():
	"""
	Affiche la page suivante
	"""
	if current_page < pages.size() - 1:
		current_page += 1
		_display_current_page()


func _display_current_page():
	"""
	Affiche la page actuelle
	"""
	if current_page >= 0 and current_page < pages.size():
		label.text = pages[current_page]
		_update_navigation_buttons()


func _split_text_into_pages(text: String) -> Array:
	"""
	Divise le texte en pages de 3 lignes maximum
	"""
	var result_pages = []
	var words = text.split(" ")
	var current_line = ""
	var line_count = 0
	var page_text = ""
	
	# Largeur approximative en caractères (ajuster selon ta police)
	var max_chars_per_line = 60
	
	for word in words:
		var test_line = current_line + (" " if current_line != "" else "") + word
		
		# Si la ligne devient trop longue
		if test_line.length() > max_chars_per_line:
			# Ajouter la ligne actuelle à la page
			page_text += current_line + "\n"
			line_count += 1
			
			# Si on a atteint 3 lignes, créer une nouvelle page
			if line_count >= lines_per_page:
				result_pages.append(page_text.strip_edges())
				page_text = ""
				line_count = 0
			
			current_line = word
		else:
			current_line = test_line
	
	# Ajouter la dernière ligne
	if current_line != "":
		page_text += current_line
		line_count += 1
	
	# Ajouter la dernière page si elle contient du texte
	if page_text.strip_edges() != "":
		result_pages.append(page_text.strip_edges())
	
	return result_pages if result_pages.size() > 0 else [""]


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
	# Ajouter les caractères à la page actuelle
	if current_page < pages.size():
		var page_content = pages[current_page]
		# Trouver où on en est dans l'affichage
		var current_display = label.text
		var chars_to_add = characters
		
		# Vérifier qu'on ne dépasse pas le contenu de la page
		var target_length = min(current_display.length() + chars_to_add.length(), page_content.length())
		label.text = page_content.substr(0, target_length)


func _on_voicebox_finished_phrase():
	# Arrêter l'animation quand le personnage finit de parler
	if lutz_animation != null:
		lutz_animation.stop_animation()
	
	# Vérifier si on a encore des pages à afficher pour ce dialogue
	if current_page < pages.size() - 1:
		# Passer à la page suivante automatiquement
		current_page += 1
		label.text = ""
		_update_navigation_buttons()
		
		# Rejouer l'animation et le son pour la page suivante
		if lutz_animation != null:
			lutz_animation.start_animation()
		voicebox.play_string(pages[current_page])
	else:
		# On a fini toutes les pages de ce dialogue
		conversation_index += 1
		if conversation_index < conversation.size():
			play_next_in_conversation()
		else:
			# Tout le dialogue est terminé, appeler le callback si défini
			if on_dialogue_finished_callback.is_valid():
				on_dialogue_finished_callback.call()
	

func play_next_in_conversation():
	if conversation_index < conversation.size():
		current_full_text = conversation[conversation_index]
		
		# Diviser le texte en pages
		pages = _split_text_into_pages(current_full_text)
		current_page = 0
		
		label.text = ""  # Clear previous text
		_update_navigation_buttons()
		
		# Démarrer l'animation avant de commencer à parler
		if lutz_animation != null:
			lutz_animation.start_animation()
		
		# Jouer la première page
		voicebox.play_string(pages[0])
