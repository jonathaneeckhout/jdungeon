extends ConditionLeaf


func tick(_actor: Node, blackboard: Blackboard) -> int:
	var aggro_target: JBody2D = blackboard.get_value("aggro_target")
	blackboard.set_value("destination_global_position", aggro_target.global_position)
	return SUCCESS
