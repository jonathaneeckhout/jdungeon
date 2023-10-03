extends ActionLeaf

@onready var wander_behavior := preload("res://scripts/classes/behaviors/JWanderBehavior.gd")

func tick(actor: Node, _blackboard: Blackboard):
	if !actor.behavior or actor.behavior.name != "WanderBehavior":
		J.logger.warn("Switchd to Wadner" + self.name)
		if actor.behavior:
			actor.behavior.queue_free()
		actor.behavior = wander_behavior.new()
		actor.behavior.name = "WanderBehavior"
		actor.behavior.actor = actor
		actor.add_child(actor.behavior)
	return SUCCESS
