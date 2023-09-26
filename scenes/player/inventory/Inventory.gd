extends Panel

const SIZE = Vector2(6, 6)

@export var gold := 0:
	set(amount):
		gold = amount
		$VBoxContainer/GoldValue.text = str(amount)

var panels = []
var mouse_above_this_panel: Panel
var location_cache = {}

@onready var player: JPlayerBody2D = $"../../../../"


func _ready():
	for x in range(SIZE.x):
		panels.append([])
		for y in range(SIZE.y):
			panels[x].append(null)

	var i = 0
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var panel = $GridContainer.get_child(i)
			panel.grid_pos = Vector2(x, y)
			panel.drag_panel_offset = (panel.grid_pos * $DragPanel.size) - $DragPanel.size / 2
			panels[x][y] = panel
			i += 1


func _input(event):
	if event.is_action_pressed("j_toggle_bag"):
		if visible:
			hide()
		else:
			show()


func register_signals():
	player.inventory.gold_added.connect(_on_gold_added)
	player.inventory.gold_removed.connect(_on_gold_removed)


func get_panel_at_pos(pos: Vector2):
	var panel_path = "Panel_%d_%d" % [int(pos.x), int(pos.y)]
	return $GridContainer.get_node(panel_path)


func _on_gold_added(total: int, _amount: int):
	gold = total


func _on_gold_removed(total: int, _amount: int):
	gold = total
