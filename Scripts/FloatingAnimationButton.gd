extends FloatingAnimation
class_name FloatingAnimationButton

# Cette classe s'attache directement à un Button et l'anime

func _initialize_animation() -> void:
	# Vérifier que le parent est bien un Button
	var parent = get_parent()
	if not parent is Button:
		push_error("FloatingAnimationButton: Le parent doit être un Button")
		return
	
	# Sauvegarder la position et rotation initiales du Button
	initial_position = parent.position
	initial_rotation = parent.rotation_degrees

func _apply_animation(offset_x: float, offset_y: float, rotation_offset: float) -> void:
	var parent = get_parent()
	if not parent is Button:
		return
	
	# Appliquer le mouvement au Button
	parent.position = initial_position + Vector2(offset_x, offset_y)
	parent.rotation_degrees = initial_rotation + rotation_offset
