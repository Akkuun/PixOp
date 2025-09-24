extends Control

var temp_from : Vector2 = Vector2.ZERO
var temp_active : bool = false
var mouse_pos : Vector2 = Vector2.ZERO
var connections : Array = [] # [{from: Vector2, to: Vector2}]

func start_connection(from_pos: Vector2):
	temp_from = from_pos
	temp_active = true

func end_connection(to_pos: Vector2):
	if temp_active:
		connections.append({"from": temp_from, "to": to_pos})
		temp_active = false
		queue_redraw()

func cancel_connection():
	temp_active = false
	queue_redraw()

func _process(_delta: float) -> void:
	if temp_active:
		mouse_pos = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	# Connexions validées
	for c in connections:
		_draw_connection(c.from, c.to, Color.GREEN)

	# Connexion en cours (suit la souris)
	if temp_active:
		_draw_connection(temp_from, mouse_pos, Color.RED)


func _draw_connection(p1: Vector2, p2: Vector2, col: Color) -> void:
	var cp1 = p1 + Vector2(100, 0)
	var cp2 = p2 - Vector2(100, 0)

	# Approximation par segments
	var points : PackedVector2Array = []
	var steps := 20
	for i in steps + 1:
		var t = float(i) / float(steps)
		points.append(_cubic_bezier(p1, cp1, cp2, p2, t))

	draw_polyline(points, col, 3.0)


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	return r0.lerp(r1, t)
