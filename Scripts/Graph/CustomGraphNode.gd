extends GraphNode

const ImageLibWrapper = preload("res://Scripts/image_lib_wrapper.gd")

var pixop_graph_node: ImageLibWrapper.PixopGraphNode
var image_lib = ImageLibWrapper.new()

func get_pixop_graph_node() -> ImageLibWrapper.PixopGraphNode:
    return pixop_graph_node

func init_pixop_graph_node(state: ImageLibWrapper.GraphState, operator_func: ImageLibWrapper.Operator, params := {}, input_nodes := []):
    pixop_graph_node = ImageLibWrapper.PixopGraphNode.new(state, operator_func, params, input_nodes)

func set_pixop_graph_node(node: ImageLibWrapper.PixopGraphNode) -> void:
    pixop_graph_node = node