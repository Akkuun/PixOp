extends Control

# This script would be attached to your drop zone area
func _ready():
	# Make sure this area can receive drops
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Set up the drop zone properties as needed
	
# Optional: Visual feedback when hovering over drop zone
func _draw():
	# Draw a subtle border or background for your drop zone
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.3, 0.2), false, 2.0)
