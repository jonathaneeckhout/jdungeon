extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard):
	var target: CharacterBody2D = blackboard.get_value("aggro_target")
	if not is_instance_valid(target):
		return FAILURE
	if actor.global_position.distance_to(target.global_position) <= actor.stats.attack_range:
		actor.destination = actor.global_position
		return SUCCESS
	return FAILURE
