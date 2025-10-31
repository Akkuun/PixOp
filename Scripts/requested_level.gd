extends Node

var tuto_done: bool = false
var level_id: int
var first_main_level_id: int = 6

func set_level_id(id: int) -> void:
    level_id = id

func get_level_id() -> int:
    return level_id

func is_tuto_done() -> bool:
    return tuto_done

func set_tuto_done(done: bool) -> void:
    tuto_done = done