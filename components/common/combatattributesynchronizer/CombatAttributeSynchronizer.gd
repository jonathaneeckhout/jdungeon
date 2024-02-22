extends Node

class_name CombatAttributeSynchronizerComponent

const COMPONENT_NAME: String = "combat_attribute_synchronizer"

@export_group("Config")
@export var watcher_synchronizer: WatcherSynchronizerComponent
@export var sync_to_client: bool = false

@export_group("Stats")
@export var attack_power_min: int = 0
@export var attack_power_max: int = 5
@export var attack_speed: float = 0.8
@export var attack_range: float = 64.0
@export var defense: int = 0
@export var movement_speed: float = 300.0

var _target_node: Node

# This value is used to check if the target node is another player
var _peer_id: int = 0

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _combat_attribute_synchronizer_rpc: CombatAttributeSynchronizerRPC = null


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	if _target_node.get("peer_id") != null:
		_peer_id = _target_node.peer_id

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _target_node.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the CombatAttributeSynchronizerRPC component.
	_combat_attribute_synchronizer_rpc = (
		_target_node
		. multiplayer_connection
		. component_list
		. get_component(CombatAttributeSynchronizerRPC.COMPONENT_NAME)
	)

	# Ensure the CombatAttributeSynchronizerRPC component is present
	assert(
		_combat_attribute_synchronizer_rpc != null,
		"Failed to get CombatAttributeSynchronizerRPC component"
	)

	if not _target_node.multiplayer_connection.is_server():
		if not _target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await _target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		if sync_to_client:
			_combat_attribute_synchronizer_rpc.request_sync(_target_node.name)


func to_json() -> Dictionary:
	var output: Dictionary = {
		"attack_power_min": attack_power_min,
		"attack_power_max": attack_power_max,
		"attack_speed": attack_speed,
		"attack_range": attack_range,
		"defense": defense,
		"movement_speed": movement_speed
	}

	return output


func from_json(data: Dictionary) -> bool:
	if not "attack_power_min" in data:
		GodotLogger.warn(
			'Failed to load combat attributes info from data, missing "attack_power_min" key'
		)
		return false

	if not "attack_power_max" in data:
		GodotLogger.warn(
			'Failed to load combat attributes info from data, missing "attack_power_max" key'
		)
		return false

	if not "attack_speed" in data:
		GodotLogger.warn(
			'Failed to load combat attributes info from data, missing "attack_speed" key'
		)
		return false

	if not "attack_speed" in data:
		GodotLogger.warn(
			'Failed to load combat attributes info from data, missing "attack_speed" key'
		)
		return false

	if not "defense" in data:
		GodotLogger.warn('Failed to load combat attributes info from data, missing "defense" key')
		return false

	if not "movement_speed" in data:
		GodotLogger.warn(
			'Failed to load combat attributes info from data, missing "movement_speed" key'
		)
		return false

	attack_power_min = data["attack_power_min"]
	attack_power_max = data["attack_power_max"]
	attack_speed = data["attack_speed"]
	attack_range = data["attack_range"]
	defense = data["defense"]
	movement_speed = data["movement_speed"]

	return true
