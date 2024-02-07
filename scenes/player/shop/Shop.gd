extends Panel

class_name Shop

const SIZE = Vector2(4, 4)

@export var player: Player = null

var gold := 0:
	set(amount):
		gold = amount
		$VBoxContainer/GoldValue.text = str(amount)

var panels = []

var vendor: NPC = null


func _ready():
	if player.multiplayer_connection.is_server():
		queue_free()
		return

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

	$CloseButton.pressed.connect(_on_close_button_pressed)


func _input(event):
	if event.is_action_pressed("j_right_click") and not JUI.above_ui:
		hide()
		vendor = null


func get_panel_at_pos(pos: Vector2):
	var panel_path = "Panel_%d_%d" % [int(pos.x), int(pos.y)]
	return $GridContainer.get_node(panel_path)


func add_item(item_uuid: String, item_class: String, price: int):
	var item: Item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class

	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var pos = Vector2(x, y)
			var panel = get_panel_at_pos(pos)
			if panel.item == null:
				panel.price = price
				panel.item = item
				return


func remove_item(pos: Vector2):
	var panel = panels[pos.x][pos.y]
	panel.item = null


func clear_shop():
	for x in range(SIZE.x):
		for y in range(SIZE.y):
			remove_item(Vector2(x, y))


func display_info(pos: Vector2, label: String, price: int):
	$InfoPanel.position = pos
	$InfoPanel/Label.text = label
	$InfoPanel/Price.text = str(price)
	$InfoPanel.show()


func hide_info():
	$InfoPanel.hide()


func _on_mouse_entered():
	JUI.above_ui = true


func _on_mouse_exited():
	JUI.above_ui = false


func open_shop(vendor_name: String):
	vendor = player.multiplayer_connection.map.npcs.get_node_or_null(vendor_name)
	if vendor == null:
		GodotLogger.info("Can not find npc=[%s]" % vendor_name)
		return

	if vendor.get("npc_class") == null:
		GodotLogger.error("vendor does not have the npc_class variable")
		return

	if vendor.get("shop") == null:
		GodotLogger.error("vendor does not have the shop variable")
		return

	$Label.text = "%s's shop" % vendor.npc_class

	clear_shop()

	for item_data in vendor.shop.inventory:
		add_item(item_data["uuid"], item_data["item_class"], item_data["price"])

	show()


func _on_close_button_pressed():
	hide()
	vendor = null
