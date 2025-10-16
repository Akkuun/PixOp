extends Node

@export var buttonPlay: Button
@export var buttonTutorial: Button
@export var buttonSandbox: Button
@export var buttonQuit: Button

# Make sure RequestedLevelData is available as an autoload singleton
# If not, you can get it via: var RequestedLevelData = get_node("/root/RequestedLevelData")

@export var firstTutorialLevelId: int = 0
@export var firstMainLevelId: int = 1



func _ready():
	buttonPlay.pressed.connect(_on_play_pressed)
	buttonQuit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	RequestedLevel.set_level_id(firstMainLevelId)
	get_tree().change_scene_to_file("res://Scenes/mainScene.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_button_sandbox_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/sandboxScene.tscn")

func _on_button_tutorial_pressed() -> void:
	RequestedLevel.set_level_id(firstTutorialLevelId)
	get_tree().change_scene_to_file("res://Scenes/mainScene.tscn")

