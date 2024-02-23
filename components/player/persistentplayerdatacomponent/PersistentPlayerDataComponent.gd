extends Node

class_name PersistentPlayerDataComponent

@export var health: HealthSynchronizerComponent = null
@export var energy: EnergySynchronizerComponent = null
@export var experience: ExperienceSynchronizerComponent = null
@export var inventory: InventorySynchronizerComponent = null
@export var equipment: EquipmentSynchronizerComponent = null
@export var player_class: ClassComponent = null
@export var store_interval_time: float = 60.0

var _target_node: Node = null


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if not _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	if _target_node.get("username") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if _target_node.get("server") == null:
		GodotLogger.error("target_node does not have the server variable")
		return

	if _target_node.get("position") == null:
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
	var data: Dictionary = _target_node.multiplayer_connection.database.load_player_data(
		_target_node.username
	)

	if data.is_empty():
		GodotLogger.info("Player=[%s] does not have peristent data" % _target_node.username)
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

	_target_node.server = data["server"]

	_target_node.position = Vector2(data["position"]["x"], data["position"]["y"])

	if health and "health" in data:
		if not health.from_json(data["health"]):
			GodotLogger.warn("Failed to load health from data")

	if energy and "energy" in data:
		if not energy.from_json(data["energy"]):
			GodotLogger.warn("Failed to load energy from data")

	if experience and "experience" in data:
		if not experience.from_json(data["experience"]):
			GodotLogger.warn("Failed to load experience from data")

	if inventory and "inventory" in data:
		if not inventory.from_json(data["inventory"]):
			GodotLogger.warn("Failed to load inventory from data")

	if equipment and "equipment" in data:
		if not equipment.from_json(data["equipment"]):
			GodotLogger.warn("Failed to load equipment from data")

	if player_class and "player_class" in data:
		if not player_class.from_json(data["player_class"]):
			GodotLogger.warn("Failed to load player class from data")

	return true


func store_persistent_data() -> bool:
	var data: Dictionary = {
		"server": _target_node.server,
		"position": {"x": _target_node.position.x, "y": _target_node.position.y}
	}

	if health:
		data["health"] = health.to_json()

	if energy:
		data["energy"] = energy.to_json()

	if experience:
		data["experience"] = experience.to_json()

	if inventory:
		data["inventory"] = inventory.to_json()

	if equipment:
		data["equipment"] = equipment.to_json()

	if player_class:
		data["player_class"] = player_class.to_json()

	return _target_node.multiplayer_connection.database.store_player_data(
		_target_node.username, data
	)


func _on_persistency_timer_timeout():
	store_persistent_data()
