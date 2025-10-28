extends Node2D

signal menu_pressed
signal retry_pressed
signal next_pressed

@export var label_path: NodePath = "Panel/Label"
@export var menu_button_path: NodePath = "Panel/Buttons/MenuButton"
@export var retry_button_path: NodePath = "Panel/Buttons/RetryButton"
@export var next_button_path: NodePath = "Panel/Buttons/NextButton"

var _label = null
var _menu_btn = null
var _retry_btn = null
var _next_btn = null

func _ready() -> void:
	print("=== POPUP _ready() called ===")
	_label = get_node_or_null(label_path) if label_path else null
	_menu_btn = get_node_or_null(menu_button_path) if menu_button_path else null
	_retry_btn = get_node_or_null(retry_button_path) if retry_button_path else null
	_next_btn = get_node_or_null(next_button_path) if next_button_path else null

	print("Label found: ", _label != null, " (path: ", label_path, ")")
	print("Menu button found: ", _menu_btn != null, " (path: ", menu_button_path, ")")
	print("Retry button found: ", _retry_btn != null, " (path: ", retry_button_path, ")")
	print("Next button found: ", _next_btn != null, " (path: ", next_button_path, ")")

	if _menu_btn:
		_menu_btn.pressed.connect(_on_menu_pressed)
		print("✓ Menu button connected")
	if _retry_btn:
		_retry_btn.pressed.connect(_on_retry_pressed)
		print("✓ Retry button connected")
	if _next_btn:
		_next_btn.pressed.connect(_on_next_pressed)
		print("✓ Next button connected")

func popup_with(message: String) -> void:
	print("=== POPUP: popup_with called with message: ", message, " ===")
	if _label:
		_label.text = message
		print("✓ Label text updated")
	else:
		print("✗ Label not found, cannot update text")
	# For Node2D, we just make it visible
	visible = true
	print("✓ Popup made visible")

func _on_menu_pressed() -> void:
	print("=== POPUP: Menu button pressed ===")
	visible = false
	emit_signal("menu_pressed")
	print("=== POPUP: menu_pressed signal emitted ===")

func _on_retry_pressed() -> void:
	print("=== POPUP: Retry button pressed ===")
	visible = false
	emit_signal("retry_pressed")
	print("=== POPUP: retry_pressed signal emitted ===")

func _on_next_pressed() -> void:
	print("=== POPUP: Next button pressed ===")
	visible = false
	emit_signal("next_pressed")
	print("=== POPUP: next_pressed signal emitted ===")
