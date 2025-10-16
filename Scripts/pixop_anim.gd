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

func animate(t: float) -> void:
    # sin oscillate
    elapsed_time += t
    var sin_values = []
    for offset in offsets:
        sin_values.append((sin((elapsed_time + offset) * anim_speed) + 1.0) / 2.0)
    
    P1Sprite.position.y = -height_amplitude * sin_values[0]
    ISprite.position.y = -height_amplitude * sin_values[1]
    XSprite.position.y = -height_amplitude * sin_values[2]
    OSprite.position.y = -height_amplitude * sin_values[3]
    P2Sprite.position.y = -height_amplitude * sin_values[4]

func _process(delta: float) -> void:
    animate(delta)