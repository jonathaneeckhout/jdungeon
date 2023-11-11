extends ActionLeaf

var destination_reached = false
var stuck = false


func tick(actor: Node, blackboard: Blackboard) -> int:
	var destination_global_position: Vector2 = blackboard.get_value("destination_global_position")
	if not destination_global_position:
		GodotLogger.error(
			"MoveTo Action used without setting 'destination_global_position' in the blackboard."
		)
		return FAILURE
	if not actor.destination_reached.is_connected(_destination_reached):
		actor.destination_reached.connect(_destination_reached)
	if not actor.stuck.is_connected(_stuck):
		actor.stuck.connect(_stuck)
	if stuck:
		blackboard.set_value("stuck_destination", actor.destination)
		_reset(actor)
		actor.destination = actor.global_position
		return FAILURE
	if actor.destination != destination_global_position:
		actor.destination = destination_global_position
	if destination_reached:
		_reset(actor)
		actor.destination = actor.global_position
		return SUCCESS
	return RUNNING


func _reset(actor: Node):
	if actor.stuck.is_connected(_stuck):
		actor.stuck.disconnect(_stuck)
	if actor.destination_reached.is_connected(_destination_reached):
		actor.destination_reached.disconnect(_destination_reached)
	stuck = false
	destination_reached = false


func interrupt(actor: Node, _blackboard: Blackboard) -> void:
	_reset(actor)


func _destination_reached() -> void:
	destination_reached = true


func _stuck() -> void:
	stuck = true
