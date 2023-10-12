extends ConditionLeaf

var is_resetting := false


func tick(actor: Node, blackboard: Blackboard):
	if blackboard.has_value("leash_position"):
		if not actor.destination_reached.is_connected(_destination_reached):
			actor.destination_reached.connect(_destination_reached)
		J.logger.info("Should leash, erasing leash_position")
		var leash_position: Vector2 = blackboard.get_value("leash_position")
		blackboard.set_value("destination_global_position", leash_position)
		blackboard.erase_value("leash_position")
		is_resetting = true
		blackboard.set_value("is_resetting", is_resetting)
		return SUCCESS
	if is_resetting:
		return SUCCESS
	if not is_resetting:
		blackboard.erase_value("is_resetting")
	return FAILURE


func _destination_reached():
	is_resetting = false
