extends ConditionLeaf

var actor_dead := false


func tick(actor: Node, blackboard: Blackboard):
	if not actor.synchronizer.died.is_connected(_on_died):
		actor.synchronizer.died.connect(_on_died)
	if actor_dead:
		blackboard.set_value("destination_global_position", actor.global_position)
		return SUCCESS
	return FAILURE


func _on_died():
	actor_dead = true
