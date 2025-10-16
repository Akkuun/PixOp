extends FloatingAnimation
class_name FloatingAnimationTextureRect

# Cette classe s'attache directement à un TextureRect et l'anime

func _initialize_animation() -> void:
	# Vérifier que le parent est bien un TextureRect
	var parent = get_parent()
	if not parent is TextureRect:
		push_error("FloatingAnimationTextureRect: Le parent doit être un TextureRect")
		return
	
	# Sauvegarder la position et rotation initiales du TextureRect
	initial_position = parent.position
	initial_rotation = parent.rotation_degrees

func _apply_animation(offset_x: float, offset_y: float, rotation_offset: float) -> void:
	var parent = get_parent()
	if not parent is TextureRect:
		return
	
	# Appliquer le mouvement au TextureRect
	parent.position = initial_position + Vector2(offset_x, offset_y)
	parent.rotation_degrees = initial_rotation + rotation_offset
