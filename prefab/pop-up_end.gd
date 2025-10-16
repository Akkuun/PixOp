extends PopupPanel

signal menu_pressed
signal retry_pressed
signal next_pressed

@export var label_path: NodePath
@export var menu_button_path: NodePath
@export var retry_button_path: NodePath
@export var next_button_path: NodePath

var _label = null
var _menu_btn = null
var _retry_btn = null
var _next_btn = null

func _ready() -> void:
	_label = get_node_or_null(label_path) if label_path else null
	_menu_btn = get_node_or_null(menu_button_path) if menu_button_path else null
	_retry_btn = get_node_or_null(retry_button_path) if retry_button_path else null
	_next_btn = get_node_or_null(next_button_path) if next_button_path else null

	if _menu_btn:
		_menu_btn.pressed.connect(_on_menu_pressed)
	if _retry_btn:
		_retry_btn.pressed.connect(_on_retry_pressed)
	if _next_btn:
		_next_btn.pressed.connect(_on_next_pressed)

func popup_with(message: String) -> void:
	if _label:
		_label.text = message
	call_deferred("popup_centered")

func _on_menu_pressed() -> void:
	hide()
	emit_signal("menu_pressed")

func _on_retry_pressed() -> void:
	hide()
	emit_signal("retry_pressed")

func _on_next_pressed() -> void:
	hide()
	emit_signal("next_pressed")
