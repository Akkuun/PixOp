extends Sprite2D

var angular_speed := PI # en radians par seconde (≈ 180°/s)

func _process(delta: float) -> void:
	var rot := angular_speed * delta
	# applique une rotation relative au transform actuel
	transform = transform.rotated(rot)
