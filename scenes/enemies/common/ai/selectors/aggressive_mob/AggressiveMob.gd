extends SelectorReactiveComposite

@export var aggro_radius: Area2D = null


func before_run(_actor: Node, blackboard: Blackboard) -> void:
	if not blackboard.has_value("aggro_radius"):
		blackboard.set_value("aggro_radius", aggro_radius)
