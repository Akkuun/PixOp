extends Control

var images := [
	preload("res://ressources/Image/file.svg"),
	preload("res://ressources/Image/file.svg"),
	preload("res://ressources/Image/file.svg"),
]

func _ready():
	for tex in images:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Centrer les images sur le Control parent
		#rect.anchor_left = 0.5
		#rect.anchor_top = 0.5
		#rect.anchor_right = 0.5
		#rect.anchor_bottom = 0.5
		rect.position = Vector2.ZERO  
		rect.pivot_offset = rect.size / 2  # pivot au centre de l'image
		rect.scale = Vector2(0.7,0.7)
		
		# Rotation aléatoire légère (-10° à +10°)
		rect.rotation_degrees = randf_range(-10.0, 10.0)
		
		add_child(rect)
