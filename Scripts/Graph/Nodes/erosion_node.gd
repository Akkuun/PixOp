extends "res://Scripts/Graph/CustomGraphNode.gd"

func _ready():
    self.title = "Erosion"
    
    init_pixop_graph_node(ImageLibWrapper.GraphState.Middle, image_lib.erosion_operator)