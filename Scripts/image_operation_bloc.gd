extends Control

enum BlockType {
	BLUR,
	COMPRESSION,
	RESIZE,
}

#default value
@export var block_type: BlockType = BlockType.BLUR

@onready var label = $ColorRect/Label

func _ready():
	match block_type:
		BlockType.BLUR:
			label.text = "Blur"
		BlockType.COMPRESSION:
			label.text = "Compression"
		BlockType.RESIZE:
			label.text = "Resize"
