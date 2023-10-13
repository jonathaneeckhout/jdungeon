extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard):
	var destination_global_position: Vector2 = blackboard.get_value("destination_global_position")
	if actor.destination != destination_global_position:
		actor.destination = destination_global_position
	return RUNNING
