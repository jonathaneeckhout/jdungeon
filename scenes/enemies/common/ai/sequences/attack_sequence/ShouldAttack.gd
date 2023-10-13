extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard):
	var target: JBody2D = blackboard.get_value("aggro_target")
	if actor.global_position.distance_to(target.global_position) >= actor.stats.attack_range:
		return SUCCESS
	return FAILURE
