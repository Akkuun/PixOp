extends Node2D

@export var P1Sprite: Sprite2D
@export var ISprite: Sprite2D
@export var XSprite: Sprite2D
@export var OSprite: Sprite2D
@export var P2Sprite: Sprite2D

var offsets = [0.2, 0.4, 0.6, 0.8, 1.0]

var elapsed_time: float = 0.0
var anim_speed: float = 3.2691
var height_amplitude: float = 20.0

# Mouse avoidance 
@export var avoidance_enabled: bool = true
@export var avoidance_radius: float = 160.0
@export var avoidance_max_displacement: float = 36.0
@export var avoidance_strength: float = 1.0

# Original positions
var _base_positions: Array[Vector2] = []
var _sprites: Array[Sprite2D] = []

func _ready() -> void:
    # Collect sprites and remember their initial local positions
    _sprites = []
    if P1Sprite: _sprites.append(P1Sprite)
    if ISprite: _sprites.append(ISprite)
    if XSprite: _sprites.append(XSprite)
    if OSprite: _sprites.append(OSprite)
    if P2Sprite: _sprites.append(P2Sprite)

    _base_positions = []
    for s in _sprites:
        _base_positions.append(s.position)

func animate(t: float) -> void:
    elapsed_time += t
    var sin_values: Array[float] = []
    for offset in offsets:
        sin_values.append((sin((elapsed_time + offset) * anim_speed) + 1.0) / 2.0)

    # Compute mouse position in this node's local space once
    var mouse_local := to_local(get_global_mouse_position())

    # mouse avoidance + vertical sine wave
    var i := 0
    if P1Sprite:
        P1Sprite.position = _compute_final_position(_base_positions[i], Vector2(0, -height_amplitude * sin_values[0]), P1Sprite, mouse_local)
        i += 1
    if ISprite:
        ISprite.position = _compute_final_position(_base_positions[i], Vector2(0, -height_amplitude * sin_values[1]), ISprite, mouse_local)
        i += 1
    if XSprite:
        XSprite.position = _compute_final_position(_base_positions[i], Vector2(0, -height_amplitude * sin_values[2]), XSprite, mouse_local)
        i += 1
    if OSprite:
        OSprite.position = _compute_final_position(_base_positions[i], Vector2(0, -height_amplitude * sin_values[3]), OSprite, mouse_local)
        i += 1
    if P2Sprite:
        P2Sprite.position = _compute_final_position(_base_positions[i], Vector2(0, -height_amplitude * sin_values[4]), P2Sprite, mouse_local)

func _compute_final_position(base_pos: Vector2, anim_offset: Vector2, sprite: Sprite2D, mouse_local: Vector2) -> Vector2:
    var disp := Vector2.ZERO
    if avoidance_enabled and sprite:
        disp = _compute_avoidance_displacement(base_pos, mouse_local)
    return base_pos + anim_offset + disp

func _compute_avoidance_displacement(origin_local: Vector2, mouse_local: Vector2) -> Vector2:
    var to_mouse := mouse_local - origin_local
    var dist := to_mouse.length()
    if dist <= 0.0001:
        return Vector2.ZERO
    if dist >= avoidance_radius:
        return Vector2.ZERO
    var away_dir := (-to_mouse).normalized()
    var factor := (1.0 - (dist / avoidance_radius)) * avoidance_strength
    var disp_len: float = clampf(factor * avoidance_max_displacement, 0.0, avoidance_max_displacement)
    return away_dir * disp_len

func _process(delta: float) -> void:
    animate(delta)