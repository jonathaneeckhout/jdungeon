extends Panel

class_name Inventory

const SIZE = Vector2(6, 6)

@export var player: Player = null
@export var inventory_synchronizer: InventorySynchronizerComponent = null

var gold := 0:
	set(amount):
		gold = amount
		$VBoxContainer/GoldValue.text = str(amount)

var panels: Array[Array] = []
var mouse_above_this_panel: InventoryPanel
var location_cache = {}


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
			panel.drag_panel_offset = (panel.grid_pos * $DragPanel.size) - $DragPanel.size / 2
			panels[x][y] = panel
			i += 1

	register_signals.call_deferred()


func _input(event):
	if JUI.chat_active:
		return

	if event.is_action_pressed("j_toggle_bag"):
		if visible:
			hide()
		else:
			update_inventory()
			show()


func register_signals():
	inventory_synchronizer.loaded.connect(_on_inventory_loaded)
	inventory_synchronizer.gold_added.connect(_on_gold_added)
	inventory_synchronizer.gold_removed.connect(_on_gold_removed)

	inventory_synchronizer.item_added.connect(_on_item_added)
	inventory_synchronizer.item_removed.connect(_on_item_removed)


func get_panel_at_pos(pos: Vector2) -> InventoryPanel:
	var panel_path = "Panel_%d_%d" % [int(pos.x), int(pos.y)]
	return $GridContainer.get_node(panel_path)


func get_panels(occupied_only: bool) -> Array[InventoryPanel]:
	var output: Array[InventoryPanel] = []
	var temp_arr: Array = []

	if occupied_only:
		for row: Array in panels:
			for panel: InventoryPanel in row:
				if panel.item is Item:
					temp_arr.append(panel)
	else:
		for row: Array in panels:
			temp_arr += row

	output.assign(temp_arr)
	return output


func swap_items(from: Panel, to: Panel):
	var temp_item: Item = to.item

	to.item = from.item
	from.item = temp_item


func update_inventory():
	var occupied_panels: Array[InventoryPanel] = get_panels(true)
	var panel_item_uuid_dictionary: Dictionary = {}
	var panels_with_invalid_items: Dictionary = {}

	#Ensure all panels have an item
	assert(
		occupied_panels.all(
			func(panel_occupied: InventoryPanel): return panel_occupied.item is Item
		)
	)

	#Store the uuid of the item that each panel has to accelerate the rest of the update.
	for panel: InventoryPanel in occupied_panels:
		panel_item_uuid_dictionary[panel.item.uuid] = panel

	#All panels are assumed invalid until proven otherwise.
	panels_with_invalid_items = panel_item_uuid_dictionary.duplicate()

	#Check every inventory item
	for inv_item: Item in inventory_synchronizer.items:
		#Unmark as invalid those who have been found in the inventory
		panels_with_invalid_items.erase(inv_item.uuid)

		#No item with this uuid has been found in the displayed inventory, add it.
		if not inv_item.uuid in panel_item_uuid_dictionary.keys():
			place_item_at_free_slot(inv_item)

		else:
			#Item found, update it.
			panel_item_uuid_dictionary[inv_item.uuid].item = inv_item
			panel_item_uuid_dictionary[inv_item.uuid].queue_redraw()

	#Clear any panels with items that are NOT in the inventory
	for item_uuid: String in panels_with_invalid_items:
		panels_with_invalid_items[item_uuid].item = null


func place_item_at_free_slot(item: Item) -> bool:
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var pos = Vector2(x, y)
			var panel: InventoryPanel = get_panel_at_pos(pos)
			if panel.item == null:
				panel.item = item
				panel.queue_redraw()
				return true
	return false


func clear_all_panels():
	for x in range(SIZE.x):
		for y in range(SIZE.y):
			var panel: InventoryPanel = panels[x][y]
			panel.item = null


func _on_mouse_entered():
	JUI.above_ui = true


func _on_mouse_exited():
	JUI.above_ui = false


func _on_inventory_loaded():
	clear_all_panels()

	gold = inventory_synchronizer.gold

	for item in inventory_synchronizer.items:
		place_item_at_free_slot(item)


func _on_gold_added(total: int, _amount: int):
	gold = total


func _on_gold_removed(total: int, _amount: int):
	gold = total


func _on_item_added(item_uuid: String, _item_class: String):
	var item: Item = inventory_synchronizer.get_item(item_uuid)

	if not item:
		return

	place_item_at_free_slot(item)


func _on_item_removed(item_uuid: String):
	for x in range(SIZE.x):
		for y in range(SIZE.y):
			var panel: InventoryPanel = panels[x][y]
			if panel.item and panel.item.uuid == item_uuid:
				panel.item = null
				return


func _on_redraw_required():
	for row: Array in panels:
		for panel: InventoryPanel in row:
			panel.queue_redraw()
