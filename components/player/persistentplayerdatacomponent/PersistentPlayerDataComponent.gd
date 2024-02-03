extends Node

class_name PersistentPlayerDataComponent

@export var stats: StatsSynchronizerComponent
@export var inventory: InventorySynchronizerComponent
@export var equipment: EquipmentSynchronizerComponent
# @export var character_class: CharacterClassComponent
@export var store_interval_time: float = 60.0
var target_node: Node


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if not target_node.multiplayer_connection.is_server():
		queue_free()
		return

	if target_node.get("username") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if target_node.get("server") == null:
		GodotLogger.error("target_node does not have the server variable")
		return

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
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
	var data: Dictionary = target_node.multiplayer_connection.database.load_player_data(
		target_node.username
	)

	if data.is_empty():
		GodotLogger.info("Player=[%s] does not have peristent data" % target_node.username)
		return true

	# This function's minimal requirement is that the world and postion key is available in the data
	if not "server" in data:
		GodotLogger.warn('Invalid format of data, missing "server" key')
		return false

	if not "position" in data:
		GodotLogger.warn('Invalid format of data, missing "position" key')
		return false

	if not "x" in data["position"]:
		GodotLogger.warn('Invalid format of data, missing "x" key')
		return false

	if not "y" in data["position"]:
		GodotLogger.warn('Invalid format of data, missing "y" key')
		return false

	target_node.server = data["server"]

	target_node.position = Vector2(data["position"]["x"], data["position"]["y"])

	if stats and "stats" in data:
		if not stats.from_json(data["stats"]):
			GodotLogger.warn("Failed to load stats from data")

	if inventory and "inventory" in data:
		if not inventory.from_json(data["inventory"]):
			GodotLogger.warn("Failed to load inventory from data")

	if equipment and "equipment" in data:
		if not equipment.from_json(data["equipment"]):
			GodotLogger.warn("Failed to load equipment from data")

	# if character_class and "characterClass" in data:
	# 	if not character_class.from_json(data["characterClass"]):
	# 		GodotLogger.warn("Failed to load character classes from data")

	return true


func store_persistent_data() -> bool:
	var data: Dictionary = {
		"server": target_node.server,
		"position": {"x": target_node.position.x, "y": target_node.position.y}
	}

	if stats:
		data["stats"] = stats.to_json()

	if inventory:
		data["inventory"] = inventory.to_json()

	if equipment:
		data["equipment"] = equipment.to_json()

	# if character_class:
	# 	data["characterClass"] = character_class.to_json()

	return target_node.multiplayer_connection.database.store_player_data(target_node.username, data)


func _on_persistency_timer_timeout():
	store_persistent_data()
