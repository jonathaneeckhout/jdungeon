@tool
extends Control

var layout := VBoxContainer.new()

func _ready():
	name = "Legend"
	layout.position.x = 10
	layout.position.y = 20
	add_child(layout)

func update(labels):
	for child in layout.get_children():
		layout.remove_child(child)
		
	for label in labels:
		var l = Label.new()
		l.text = label.name
		l.add_theme_color_override("font_color", label.color)
		layout.add_child(l)
