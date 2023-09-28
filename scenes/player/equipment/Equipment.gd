extends Panel

const SIZE = Vector2(2, 4)

@export var gold := 0:
	set(amount):
		gold = amount
		$VBoxContainer/GoldValue.text = str(amount)

var panels = []
var mouse_above_this_panel: EquipmentPanel


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	for x in range(SIZE.x):
		panels.append([])
		for y in range(SIZE.y):
			panels[x].append(null)

	var i = 0
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var panel = $GridContainer.get_child(i)
			panel.grid_pos = Vector2(x, y)
			panels[x][y] = panel
			i += 1


func _input(event):
	if event.is_action_pressed("j_toggle_equipment"):
		if visible:
			hide()
		else:
			show()


func _on_mouse_entered():
	JUI.above_ui = true


func _on_mouse_exited():
	JUI.above_ui = false
