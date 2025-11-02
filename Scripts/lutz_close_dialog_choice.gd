extends CanvasLayer

@export var close_button: Button

func _ready() -> void:
    if close_button:
        close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed() -> void:
    self.visible = false