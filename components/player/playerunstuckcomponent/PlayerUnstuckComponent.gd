extends Node

class_name PlayerUnstuckComponent

const COMPONENT_NAME: String = "player_unstuck"

var _target_node: Node

var _player_unstuck_rpc: PlayerUnstuckRPC = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	# Get the PlayerUnstuckRPC component.
	_player_unstuck_rpc = (_target_node.multiplayer_connection.component_list.get_component(
		PlayerUnstuckRPC.COMPONENT_NAME
	))

	assert(_player_unstuck_rpc != null, "Failed to get PlayerUnstuckRPC component")


func unstuck():
	GodotLogger.info("Unstucking player")
	_player_unstuck_rpc.unstuck()
