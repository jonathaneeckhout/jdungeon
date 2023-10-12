extends ConditionLeaf


func tick(_actor: Node, blackboard: Blackboard):
	if blackboard.has_value("leash_position"):
		var leash_position: Vector2 = blackboard.get_value("leash_position")
		blackboard.set_value("destination_global_position", leash_position)
		blackboard.erase_value("leash_position")
		return SUCCESS
	return FAILURE
