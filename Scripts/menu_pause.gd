extends Control
var audio_server = AudioServer

func _ready() -> void:
	hide()
	$AnimationPlayer.play("RESET")
	
	# Set all AudioStreamPlayer nodes to continue during pause
	_setup_audio_players()

func _setup_audio_players():
	# Find and configure all AudioStreamPlayer nodes to continue during pause
	_configure_audio_nodes(get_tree().current_scene)

func _configure_audio_nodes(node: Node):
	if node is AudioStreamPlayer:
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		print("DEBUG: Configured AudioStreamPlayer for pause: ", node.name)
	
	for child in node.get_children():
		_configure_audio_nodes(child)

func pause():
	show()
	get_tree().paused = true
	$AnimationPlayer.play("pause_blur")

	var bus_idx = audio_server.get_bus_index("Resume")
	if bus_idx != -1:
		audio_server.set_bus_effect_enabled(bus_idx, 0, true) # active LowPass
		audio_server.set_bus_effect_enabled(bus_idx, 1, true) # active Reverb
		print("DEBUG: Pause effects enabled on Resume bus")
	else:
		print("Warning: Resume bus not found!")
	
	# Ensure audio continues playing during pause
	_configure_audio_nodes(get_tree().current_scene)
	
	# Mettre en pause le dialogue si il existe
	var dialogue_system = _find_dialogue_system()
	if dialogue_system and dialogue_system.has_method("pause_dialogue"):
		dialogue_system.pause_dialogue()
		print("DEBUG: Dialogue paused")

func resume():
	hide()
	get_tree().paused = false
	$AnimationPlayer.play_backwards("pause_blur")

	var bus_idx = audio_server.get_bus_index("Resume")
	if bus_idx != -1:
		audio_server.set_bus_effect_enabled(bus_idx, 0, false)
		audio_server.set_bus_effect_enabled(bus_idx, 1, false)
		print("DEBUG: Pause effects disabled on Resume bus")
	else:
		print("Warning: Resume bus not found!")
	
	# Reprendre le dialogue si il existe
	var dialogue_system = _find_dialogue_system()
	if dialogue_system and dialogue_system.has_method("resume_dialogue"):
		dialogue_system.resume_dialogue()
		print("DEBUG: Dialogue resumed")

func _find_dialogue_system() -> Node:
	"""
	Cherche le système de dialogue dans la scène
	"""
	var root = get_tree().current_scene
	if not root:
		return null
	
	# Chercher dans le chemin typique
	var dialogue = root.get_node_or_null("TutorialUI/Lutz Animation/TextureRect")
	if dialogue:
		return dialogue
	
	# Chercher dans tous les enfants
	for child in root.get_children():
		if child.has_method("pause_dialogue"):
			return child
	
	return null
func testEsc():
	if Input.is_action_just_pressed("Escape") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("Escape") and get_tree().paused:
		resume()

func _on_resume_pressed() -> void:
	resume()


func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func _process(_delta: float) -> void:
	testEsc()


func _on_esc_button_pressed() -> void:
	if !get_tree().paused:
		pause()
	elif get_tree().paused:
		resume()
