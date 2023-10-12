extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard):
	blackboard.set_value("destination_global_position", actor.global_position)
	return SUCCESS
