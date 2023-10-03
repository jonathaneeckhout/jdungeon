extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard):
	if !actor.behavior or actor.behavior.name != "WanderBehavior":
		if actor.behavior:
			actor.behavior.queue_free()
		actor.behavior = JWanderBehavior.new()
		actor.behavior.name = "WanderBehavior"
		actor.behavior.actor = actor
		actor.add_child(actor.behavior)
	return SUCCESS
