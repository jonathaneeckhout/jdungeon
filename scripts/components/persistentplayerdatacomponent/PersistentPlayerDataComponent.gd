extends Node

class_name PersistentPlayerDataComponent

@export var stats: StatsSynchronizerComponent
@export var inventory: InventorySynchronizerComponent
@export var equipment: EquipmentSynchronizerComponent
@export var store_interval_time: float = 60.0
var target_node: Node


func _ready():
	if not J.is_server():
		return

	target_node = get_parent()

	if target_node.get("username") == null:
		J.logger.error("target_node does not have the position variable")
		return

	if target_node.get("position") == null:
		J.logger.error("target_node does not have the position variable")
		return

	var persistency_timer = Timer.new()
	persistency_timer.name = "PersistencyTimer"
	persistency_timer.autostart = true
	persistency_timer.wait_time = store_interval_time
	persistency_timer.timeout.connect(_on_persistency_timer_timeout)
	add_child(persistency_timer)

	load_persistent_data.call_deferred()

	tree_exiting.connect(_on_exiting_tree)


func _on_exiting_tree():
	store_persistent_data()


func load_persistent_data() -> bool:
	var data: Dictionary = J.server.database.load_player_data(target_node.username)

	if data.is_empty():
		J.logger.info("Player=[%s] does not have peristent data" % target_node.username)
		return true

	# This function's minimal requirement is that the postion key is available in the data
	if not "position" in data:
		J.logger.warn('Invalid format of data, missing "position" key')
		return false

	if not "x" in data["position"]:
		J.logger.warn('Invalid format of data, missing "x" key')
		return false

	if not "y" in data["position"]:
		J.logger.warn('Invalid format of data, missing "y" key')
		return false

	target_node.position = Vector2(data["position"]["x"], data["position"]["y"])

	if stats and "stats" in data:
		if not stats.from_json(data["stats"]):
			J.logger.warn("Failed to load stats from data")

	if inventory and "inventory" in data:
		if not inventory.from_json(data["inventory"]):
			J.logger.warn("Failed to load inventory from data")

	if equipment and "equipment" in data:
		if not equipment.from_json(data["equipment"]):
			J.logger.warn("Failed to load equipment from data")

	return true


func store_persistent_data() -> bool:
	var data: Dictionary = {"position": {"x": target_node.position.x, "y": target_node.position.y}}

	if stats:
		data["stats"] = stats.to_json()

	if inventory:
		data["inventory"] = inventory.to_json()

	if equipment:
		data["equipment"] = equipment.to_json()

	return J.server.database.store_player_data(target_node.username, data)


func _on_persistency_timer_timeout():
	store_persistent_data()
