extends Node

@export var buttonPlay: Button
@export var buttonTutorial: Button
@export var buttonSandbox: Button
@export var buttonQuit: Button

# Make sure RequestedLevelData is available as an autoload singleton
# If not, you can get it via: var RequestedLevelData = get_node("/root/RequestedLevelData")

@export var firstTutorialLevelId: int = 0
@export var firstMainLevelId: int = 1

var confirmation_popup: AcceptDialog



func _ready():
	buttonPlay.pressed.connect(_on_play_pressed)
	buttonQuit.pressed.connect(_on_quit_pressed)
	
	# Créer la popup de confirmation
	_create_confirmation_popup()

func _create_confirmation_popup():
	confirmation_popup = AcceptDialog.new()
	confirmation_popup.title = "Confirmation"
	confirmation_popup.dialog_text = "Êtes-vous sûr de vouloir commencer à jouer sans avoir fait le tutoriel ?"
	confirmation_popup.ok_button_text = "Oui"
	confirmation_popup.add_cancel_button("Non")
	
	# Ajouter la popup à la scène
	add_child(confirmation_popup)
	
	# Connecter les signaux
	confirmation_popup.confirmed.connect(_on_popup_confirmed)
	confirmation_popup.canceled.connect(_on_popup_canceled)

func _on_play_pressed():
	# Afficher la popup de confirmation
	confirmation_popup.popup_centered()

func _on_popup_confirmed():
	# L'utilisateur a cliqué "Oui", aller au niveau de jeu
	RequestedLevel.set_level_id(firstMainLevelId)
	get_tree().change_scene_to_file("res://Scenes/mainScene.tscn")

func _on_popup_canceled():
	# L'utilisateur a cliqué "Non", fermer la popup (déjà fait automatiquement)
	pass

func _on_quit_pressed():
	get_tree().quit()

func _on_button_sandbox_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/sandboxScene.tscn")

func _on_button_tutorial_pressed() -> void:
	RequestedLevel.set_level_id(firstTutorialLevelId)
	get_tree().change_scene_to_file("res://Scenes/mainScene.tscn")
