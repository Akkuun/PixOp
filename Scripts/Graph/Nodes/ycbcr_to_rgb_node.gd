extends GraphNode

func _ready():
	# Set up the node title
	self.title = "YCbCr to RGB"
	
	# Configure slot colors
	var rgb_color = Color.WHITE
	var y_color = Color(0.7, 0.7, 0.7)    # Gray for Y
	var cr_color = Color(1.0, 0.3, 0.3)   # Red for Cr
	var cb_color = Color.DODGER_BLUE
	
	# Universal slot type
	var universal_type = 0
	
	# Set minimum width for the GraphNode
	self.custom_minimum_size = Vector2(180, 0)
	
	# Add top spacer
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 5
	add_child(top_spacer)
	set_slot(0, false, universal_type, Color.BLACK, false, universal_type, Color.BLACK)
	
	# First slot - Y (input only)
	var hbox1 = HBoxContainer.new()
	hbox1.size_flags_horizontal = Control.SIZE_FILL
	hbox1.custom_minimum_size.y = 30
	
	var label1 = Label.new()
	label1.text = "Y"
	label1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# We're adding a margin container for the left label
	var margin1 = MarginContainer.new()
	margin1.add_theme_constant_override("margin_left", 5)  # More space from the slot
	margin1.add_child(label1)
	
	hbox1.add_child(margin1)
	add_child(hbox1)
	set_slot(1, true, universal_type, y_color, false, universal_type, Color.BLACK)
	
	# Second slot - Cb (input only)
	var hbox2 = HBoxContainer.new()
	hbox2.size_flags_horizontal = Control.SIZE_FILL
	hbox2.custom_minimum_size.y = 30
	
	var label2 = Label.new()
	label2.text = "Cb"
	label2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin2 = MarginContainer.new()
	margin2.add_theme_constant_override("margin_left", 5)
	margin2.add_child(label2)
	
	hbox2.add_child(margin2)
	add_child(hbox2)
	set_slot(2, true, universal_type, cb_color, false, universal_type, Color.BLACK)
	
	# Third slot - Cr (input only)
	var hbox3 = HBoxContainer.new()
	hbox3.size_flags_horizontal = Control.SIZE_FILL
	hbox3.custom_minimum_size.y = 30
	
	var label3 = Label.new()
	label3.text = "Cr"
	label3.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin3 = MarginContainer.new()
	margin3.add_theme_constant_override("margin_left", 5)
	margin3.add_child(label3)
	
	hbox3.add_child(margin3)
	add_child(hbox3)
	set_slot(3, true, universal_type, cr_color, false, universal_type, Color.BLACK)
	
	# Fourth slot - RGB (output only)
	var hbox4 = HBoxContainer.new()
	hbox4.size_flags_horizontal = Control.SIZE_FILL
	hbox4.custom_minimum_size.y = 30
	hbox4.alignment = BoxContainer.ALIGNMENT_END  # Align to the right
	
	var label4 = Label.new()
	label4.text = "RGB"
	label4.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var margin4 = MarginContainer.new()
	margin4.add_theme_constant_override("margin_right", 20)  # More space before the slot
	margin4.add_child(label4)
	
	hbox4.add_child(margin4)
	add_child(hbox4)
	set_slot(4, false, universal_type, Color.BLACK, true, universal_type, rgb_color)
	
	# Add bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size.y = 10
	add_child(bottom_spacer)
	set_slot(5, false, universal_type, Color.BLACK, false, universal_type, Color.BLACK)
