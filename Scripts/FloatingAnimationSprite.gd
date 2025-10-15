extends FloatingAnimation
class_name FloatingAnimationSprite

# Cette classe s'attache directement à un Sprite2D et l'anime
# Avec des valeurs plus légères que les autres animations

func _ready():
	# Réduire les amplitudes pour un effet très léger sur les sprites
	float_amplitude = 1.0  # Très petit mouvement vertical
	horizontal_sway = 1.5  # Très petit balancement horizontal
	rotation_amount = 1.0  # Rotation minimale
	
	# Appeler le _ready() de la classe parent
	super._ready()

func _initialize_animation() -> void:
	# Vérifier que le parent est bien un Sprite2D
	var parent = get_parent()
	if not parent is Sprite2D:
		push_error("FloatingAnimationSprite: Le parent doit être un Sprite2D")
		return
	
	# Sauvegarder la position et rotation initiales du Sprite2D
	initial_position = parent.position
	initial_rotation = parent.rotation_degrees

func _apply_animation(offset_x: float, offset_y: float, rotation_offset: float) -> void:
	var parent = get_parent()
	if not parent is Sprite2D:
		return
	
	# Appliquer le mouvement au Sprite2D
	parent.position = initial_position + Vector2(offset_x, offset_y)
	parent.rotation_degrees = initial_rotation + rotation_offset
