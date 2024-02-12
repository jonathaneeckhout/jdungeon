@tool
extends Control

var vert_grid: Array
var hor_grid: Array

func _ready():
	name = "Grid"

func _draw() -> void:
	for line in hor_grid:
		draw_line(line[0], line[1], Color(1,1,1,0.3))
		
	for line in vert_grid:
		draw_line(line[0], line[1], Color(1,1,1,0.3))
