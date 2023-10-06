extends Panel

const SIZE = Vector2(2, 4)

@export var gold := 0:
	set(amount):
		gold = amount
		$VBoxContainer/GoldValue.text = str(amount)

var panels = []

@onready var player: JPlayerBody2D = $"../../../../"


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


func register_signals():
	player.equipment.loaded.connect(_on_equipment_loaded)
	player.equipment.item_added.connect(_on_item_added)
	player.equipment.item_removed.connect(_on_item_removed)


func get_panel_at_slot(equipment_slot: String) -> EquipmentPanel:
	var panel_path = "Panel_%s" % equipment_slot
	return $GridContainer.get_node(panel_path)


func clear_all_panels():
	for x in range(SIZE.x):
		for y in range(SIZE.y):
			var panel: EquipmentPanel = panels[x][y]
			panel.item = null


func _on_mouse_entered():
	JUI.above_ui = true


func _on_mouse_exited():
	JUI.above_ui = false


func _on_item_added(item_uuid: String, _item_class: String):
	var item: JItem = player.equipment.get_item(item_uuid)
	if item == null:
		return

	var panel = get_panel_at_slot(item.equipment_slot)
	if panel:
		panel.item = item


func _on_item_removed(item_uuid: String):
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var panel: EquipmentPanel = panels[x][y]
			if panel.item and panel.item.uuid == item_uuid:
				panel.item = null


func _on_equipment_loaded():
	clear_all_panels()

	for slot in player.equipment.items:
		var item: JItem = player.equipment.items[slot]
		if item:
			var panel = get_panel_at_slot(item.equipment_slot)
			if panel:
				panel.item = item
