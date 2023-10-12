extends ConditionLeaf

@export var flee_magnitude := 350.0

var flee_destination := Vector2.ZERO


func tick(actor: Node, blackboard: Blackboard) -> int:
	actor.movement_multiplier = 3
	var attacker_position: Vector2 = blackboard.get_value("aggro_target").position
	flee_destination = _flee_to(attacker_position, actor.position)
	blackboard.set_value("destination_global_position", flee_destination)
	return SUCCESS


func _flee_to(attacker_position: Vector2, actor_position: Vector2) -> Vector2:
	var flee_direction := attacker_position.direction_to(actor_position)
	return actor_position + (flee_direction * flee_magnitude)
