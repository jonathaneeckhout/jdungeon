@tool
extends Label

func _ready():
	name = "Coordinate"
	anchor_right = 1
	anchor_left = 1
	offset_right = -20
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	text = "(0.0, 0.0)"
