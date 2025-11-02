extends Node

var tuto_done: bool = false
var level_id: int
var first_main_level_id: int = 6
var number_of_levels: int = 0

func _init() -> void:
    #count number of levels from levels_data.json
    var levels_data = load("res://Levels/levels_data.json").get_data()
    number_of_levels = levels_data.size() - 1 #subtract 1 for the sandbox
    print("Number of levels: ", number_of_levels)

func set_level_id(id: int) -> void:
    level_id = id

func get_level_id() -> int:
    return level_id

func is_tuto_done() -> bool:
    return tuto_done

func set_tuto_done(done: bool) -> void:
    tuto_done = done