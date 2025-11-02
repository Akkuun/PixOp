extends Control

@export var topleft: TextureRect
@export var topright: TextureRect
@export var bottomleft: TextureRect
@export var bottomright: TextureRect

@export var center_pos: Control


@export var anim_amplitude: float = 3.5
@export var oscillation_period: float = 0.6

var anim_timer: float = 0.0

# Initial positions
var topleft_start: Vector2
var topright_start: Vector2
var bottomleft_start: Vector2
var bottomright_start: Vector2

# Store initial center and fixed directions (from center to each start)
var center_start: Vector2
var dir_tl: Vector2 = Vector2.ZERO
var dir_tr: Vector2 = Vector2.ZERO
var dir_bl: Vector2 = Vector2.ZERO
var dir_br: Vector2 = Vector2.ZERO

func _ready() -> void:
	center_start = center_pos.position if center_pos else Vector2.ZERO

	if topleft:
		topleft_start = topleft.position
		var v_tl: Vector2 = topleft_start - center_start
		var l_tl: float = v_tl.length()
		dir_tl = (v_tl / l_tl) if l_tl > 0.0001 else Vector2(-1, -1).normalized()
	if topright:
		topright_start = topright.position
		var v_tr: Vector2 = topright_start - center_start
		var l_tr: float = v_tr.length()
		dir_tr = (v_tr / l_tr) if l_tr > 0.0001 else Vector2(1, -1).normalized()
	if bottomleft:
		bottomleft_start = bottomleft.position
		var v_bl: Vector2 = bottomleft_start - center_start
		var l_bl: float = v_bl.length()
		dir_bl = (v_bl / l_bl) if l_bl > 0.0001 else Vector2(-1, 1).normalized()
	if bottomright:
		bottomright_start = bottomright.position
		var v_br: Vector2 = bottomright_start - center_start
		var l_br: float = v_br.length()
		dir_br = (v_br / l_br) if l_br > 0.0001 else Vector2(1, 1).normalized()

func _process(delta: float) -> void:
	anim_timer += delta
	var period: float = max(0.001, oscillation_period)

	var phase: float = PI * (anim_timer / period)
	var factor: float = absf(sin(phase))

	var amp: float = anim_amplitude

	if topleft:
		topleft.position = topleft_start + dir_tl * amp * factor

	if topright:
		topright.position = topright_start + dir_tr * amp * factor

	if bottomleft:
		bottomleft.position = bottomleft_start + dir_bl * amp * factor

	if bottomright:
		bottomright.position = bottomright_start + dir_br * amp * factor
