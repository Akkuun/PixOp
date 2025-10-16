extends Node

@export var buttonPlay: Button
@export var buttonQuit: Button



func _ready():
	
	
	buttonPlay.pressed.connect(_on_play_pressed)
	buttonQuit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scenes/mainScene2D.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_button_sandbox_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/sandboxScene.tscn")

func _on_button_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/tutorialScene.tscn")

