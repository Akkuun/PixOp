extends Node
class_name FloatingAnimation

# Paramètres de l'animation de flottement
@export var float_amplitude: float = 2.0  # Hauteur du mouvement en pixels
@export var float_speed: float = 2.0  # Vitesse du mouvement
@export var horizontal_sway: float = 3.0  # Balancement horizontal (optionnel)
@export var rotation_amount: float = 3.0  # Rotation en degrés (optionnel)

var time: float = 0.0
var initial_position: Vector2
var initial_rotation: float
var random_offset: float = 0.0  # Décalage aléatoire pour varier les animations
var random_speed_multiplier: float = 1.0  # Multiplicateur de vitesse aléatoire
var random_horizontal_phase: float = 0.0  # Phase aléatoire pour le mouvement horizontal
var random_rotation_phase: float = 0.0  # Phase aléatoire pour la rotation

func _ready():
	# Générer plusieurs valeurs aléatoires pour une vraie variation
	random_offset = randf() * TAU  # TAU = 2*PI, donc un décalage entre 0 et 360°
	random_speed_multiplier = randf_range(0.8, 1.2)  # Vitesse variant de ±20%
	random_horizontal_phase = randf() * TAU  # Phase indépendante pour horizontal
	random_rotation_phase = randf() * TAU  # Phase indépendante pour rotation
	
	# Attendre un frame pour que le layout soit initialisé
	await get_tree().process_frame
	
	# Méthode virtuelle à implémenter par les classes filles
	_initialize_animation()

func _process(delta):
	time += delta * float_speed * random_speed_multiplier
	
	# Mouvement vertical (flottement principal) avec décalage aléatoire
	var offset_y = sin(time + random_offset) * float_amplitude
	
	# Mouvement horizontal (balancement léger) avec phase complètement différente
	var offset_x = sin(time * 0.7 + random_horizontal_phase) * horizontal_sway
	
	# Rotation légère pour plus de naturel avec phase aléatoire indépendante
	var rotation_offset = sin(time * 0.5 + random_rotation_phase) * rotation_amount
	
	# Méthode virtuelle à implémenter par les classes filles
	_apply_animation(offset_x, offset_y, rotation_offset)

# Méthode virtuelle : initialiser les positions/rotations initiales
# À surcharger dans les classes filles
func _initialize_animation() -> void:
	push_warning("FloatingAnimation: _initialize_animation() n'est pas implémentée")

# Méthode virtuelle : appliquer l'animation au node
# À surcharger dans les classes filles
func _apply_animation(offset_x: float, offset_y: float, rotation_offset: float) -> void:
	push_warning("FloatingAnimation: _apply_animation() n'est pas implémentée")
