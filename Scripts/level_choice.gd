extends Control

signal level_selected(level_id: int)

@export var level_list : VBoxContainer
@export var level_item_scene : PackedScene
@export var select_blend_duration: float = 0.3

@export var cancel_button : Button
@export var load_level_button : Button

var selected_level_id: int = -1
 

var images_folder = "res://Levels"

func _ready() -> void:
	var current_hbox: HBoxContainer = null
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if load_level_button:
		load_level_button.pressed.connect(_on_load_pressed)

	for i in range(RequestedLevel.number_of_levels):
		# Create a new HBoxContainer every 5 levels
		if i % 5 == 0:
			current_hbox = HBoxContainer.new()
			current_hbox.add_theme_constant_override("separation", 20)
			level_list.add_child(current_hbox)
		
		var level_label = "";
		if i < RequestedLevel.first_main_level_id:
			level_label = "Tutoriel " + str(i+1)
		else:
			level_label = "Niveau " + str(i - RequestedLevel.first_main_level_id + 1)
		
		var level_path = images_folder + "/" + str(i)
		var texCurrent := load(level_path + "/current.png")
		var texTarget := load(level_path + "/target.png")
		
		# Instantiate the level item scene
		var level_item = level_item_scene.instantiate()
		
		# Set the label text
		var label = level_item.get_node("LevelLabel")
		label.text = level_label
		# Ensure label doesn't block clicks
		if label is Control:
			(label as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Set the image texture and blend shader material
		var image: TextureRect = level_item.get_node("LevelImage")
		image.texture = texCurrent
		var swipe_shader := load("res://ressources/shader/highlight.gdshader")
		if swipe_shader:
			var mat := ShaderMaterial.new()
			mat.shader = swipe_shader
			mat.set_shader_parameter("target_tex", texTarget)
			mat.set_shader_parameter("progress", 0.0)
			image.material = mat
		# Let scroll wheel events reach the ScrollContainer
		image.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Visible Button overlay for selection (as a child of the image)
		var click_button := Button.new()
		click_button.name = "ClickButton"
		click_button.focus_mode = Control.FOCUS_NONE
		click_button.flat = true
		click_button.mouse_filter = Control.MOUSE_FILTER_STOP
		# Cover the whole image dynamically
		click_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click_button.z_as_relative = false
		click_button.z_index = 4096  # Max practical z for Controls (absolute)
		click_button.visible = true
		# Make it invisible but clickable
		click_button.modulate = Color(1,1,1,0)
		click_button.text = ""
		click_button.tooltip_text = ""

		# Store the level id and selection state
		click_button.set_meta("level_id", i)
		
		# Connect signals using lambdas so args are bound correctly
		click_button.gui_input.connect(func(event): _on_click_button_gui_input(event, click_button))
		click_button.pressed.connect(func(): _on_level_item_clicked(click_button))
		# Hover state for blend preview
		click_button.set_meta("hovered", false)
		click_button.mouse_entered.connect(func(): click_button.set_meta("hovered", true))
		click_button.mouse_exited.connect(func(): click_button.set_meta("hovered", false))

		# Also allow clicking the image itself as a fallback path (optional)
		image.gui_input.connect(func(event): _on_level_image_gui_input(event, i))
		
		# Add the clickable button as a child of the image so Container won't re-layout it
		image.add_child(click_button)
		
		# Add level item to the current HBoxContainer
		current_hbox.add_child(level_item)
		

func _on_level_item_clicked(click_button: Button) -> void:
	# Deselect all other levels
	for hbox in level_list.get_children():
		for child in hbox.get_children():
			# Click button is a child of LevelImage; search recursively
			var btn: Button = child.find_child("ClickButton", true, false)
			if btn:
				pass
			# Hide highlight on this item if present
			var hl: Control = child.get_node_or_null("Highlight")
			if hl:
				hl.visible = false
	
	# Select this level
	selected_level_id = click_button.get_meta("level_id")
	# Show the built-in Highlight node on this level item root
	var level_item_root := click_button.get_parent().get_parent()
	var selected_hl: Control = level_item_root.get_node_or_null("Highlight")
	if selected_hl:
		selected_hl.visible = true
	print("[selected] selected_level_id=", selected_level_id)
	emit_signal("level_selected", selected_level_id)



# Fallback: handle clicks on the image if the button overlay didn't capture input
func _on_level_image_gui_input(event: InputEvent, level_id: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_level_by_id(level_id)

# Capture only left-clicks on the overlay and allow scrolling to pass through
func _on_click_button_gui_input(event: InputEvent, click_button: Button) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_on_level_item_clicked(click_button)

func _process(delta: float) -> void:
	# Smoothly blend selected item to target (1.0) and others to current (0.0)
	for hbox in level_list.get_children():
		for child in hbox.get_children():
			var btn: Button = child.find_child("ClickButton", true, false)
			if not btn:
				continue
			var img: TextureRect = btn.get_parent()
			if img and img.material is ShaderMaterial:
				var mat := img.material as ShaderMaterial
				var p: float = 0.0
				if mat.get_shader_parameter("progress") != null:
					p = float(mat.get_shader_parameter("progress"))
				var target: float = 0.0
				var hovered: bool = bool(btn.get_meta("hovered", false))
				if hovered:
					target = 1.0
				if selected_level_id != -1 and int(btn.get_meta("level_id", -1)) == selected_level_id:
					# Selection wins; keep fully blended
					target = 1.0
				var dur: float = max(select_blend_duration, 0.0001)
				var step := delta / dur
				if p < target:
					p = min(target, p + step)
				elif p > target:
					p = max(target, p - step)
				mat.set_shader_parameter("progress", p)

func _select_level_by_id(level_id: int) -> void:
	# Deselect all buttons
	for hbox in level_list.get_children():
		for child in hbox.get_children():
			var btn: Button = child.find_child("ClickButton", true, false)
			if btn:
				pass
			# Hide highlight on this item if present
			var hl2: Control = child.get_node_or_null("Highlight")
			if hl2:
				hl2.visible = false
	# Select target
	var target_btn := _get_button_for_level(level_id)
	if target_btn:
		selected_level_id = level_id
		# Show highlight for programmatic selection
		var root := target_btn.get_parent().get_parent()
		var hls: Control = root.get_node_or_null("Highlight")
		if hls:
			hls.visible = true

func _get_button_for_level(level_id: int) -> Button:
	for hbox in level_list.get_children():
		for child in hbox.get_children():
			var btn: Button = child.find_child("ClickButton", true, false)
			if btn and btn.get_meta("level_id", -1) == level_id:
				return btn
	return null


# UI buttons
func _on_cancel_pressed() -> void:
	queue_free()

func _on_load_pressed() -> void:
	if selected_level_id == -1:
		push_warning("No level selected.")
		return
	RequestedLevel.set_level_id(selected_level_id)
	get_tree().change_scene_to_file("res://Scenes/mainScene.tscn")
		
