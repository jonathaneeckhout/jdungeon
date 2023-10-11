extends ActionLeaf


func tick(actor: Node, _blackboard: Blackboard):
	actor.beehave_tree.enabled = false
	return SUCCESS
