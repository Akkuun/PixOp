extends HSlider

func _ready() -> void:
	min_value = 0
	max_value = 100
	
	# Set initial value based on current main bus volume
	var current_db = AudioServer.get_bus_volume_db(0)
	var linear_volume = db_to_linear(current_db)
	value = linear_volume * 100
	
	value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float) -> void:
	# Convert slider value (0-100) to linear volume (0-1), then to dB
	var linear_volume = new_value / 100.0
	var db_volume = linear_to_db(linear_volume)
	AudioServer.set_bus_volume_db(0, db_volume)

