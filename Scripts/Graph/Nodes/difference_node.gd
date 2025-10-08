extends GraphNode

func _ready():
	self.title = "Difference"
	
	var rgb_color = Color.WHITE
	var y_color = Color(0.7, 0.7, 0.7)
	var universal_type = 0
	self.custom_minimum_size = Vector2(200, 0)

	# Spacer haut
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 20
	add_child(top_spacer)
	set_slot(0, false, universal_type, y_color, false, universal_type, y_color)

	# Entrée 1 : RGB
	var hbox1 = HBoxContainer.new()
	hbox1.size_flags_horizontal = Control.SIZE_FILL
	hbox1.custom_minimum_size.y = 30
	var label1 = Label.new()
	label1.text = "Img                   Img"
	label1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin1 = MarginContainer.new()
	margin1.add_theme_constant_override("margin_left", 20)
	margin1.add_child(label1)
	hbox1.add_child(margin1)
	add_child(hbox1)
	set_slot(1, false, universal_type, rgb_color, false, universal_type, y_color)

	# Entrée 2 : Y
	var hbox2 = HBoxContainer.new()
	hbox2.size_flags_horizontal = Control.SIZE_FILL
	hbox2.custom_minimum_size.y = 30
	var label2 = Label.new()
	label2.text = "TruthMap"
	label2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin2 = MarginContainer.new()
	margin2.add_theme_constant_override("margin_left", 20)
	margin2.add_child(label2)
	hbox2.add_child(margin2)
	add_child(hbox2)
	set_slot(2, true, universal_type, y_color, true, universal_type, y_color)

	# Entrée 3 : Extra (par exemple Cr ou autre)
	var hbox3 = HBoxContainer.new()
	hbox3.size_flags_horizontal = Control.SIZE_FILL
	hbox3.custom_minimum_size.y = 30
	var label3 = Label.new()
	label3.text = ""
	label3.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin3 = MarginContainer.new()
	margin3.add_theme_constant_override("margin_left", 20)
	margin3.add_child(label3)
	hbox3.add_child(margin3)
	add_child(hbox3)
	set_slot(3, true, universal_type, y_color, false, universal_type, y_color)
