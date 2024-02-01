extends Node

## This component is used to simulate the velocity on this component at the client side as the velocity is not passed over the network.
class_name VelocitySimulatorComponent

var _target_node: Node

var _prev_pos: Vector2 = Vector2.ZERO


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This component should not run on the server
	if _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	# This component should not run on your own player
	if (
		_target_node.get("peer_id") != null
		and _target_node.multiplayer_connection.is_own_player(_target_node)
	):
		queue_free()
		return

	_prev_pos = _target_node.position


func _physics_process(delta: float):
	_target_node.velocity = (_target_node.position - _prev_pos) / delta
	_prev_pos = _target_node.position
