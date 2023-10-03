extends ConditionLeaf

var was_attacked = false
var attacker_name = null
func tick(actor: Node, blackboard: Blackboard):
	if not actor.synchronizer.got_hurt.is_connected(_on_got_hurt):
		actor.synchronizer.got_hurt.connect(_on_got_hurt)
	if was_attacked:
		was_attacked = false
		actor.synchronizer.got_hurt.disconnect(_on_got_hurt)
		blackboard.set_value("attacker_global_position", get_node("/root/Root/World/JEntities/JPlayers/" + attacker_name).global_position)
		return SUCCESS
	return FAILURE

func _on_got_hurt(from: String, _hp: int, _max_hp: int, _damage: int):
	attacker_name = from
	was_attacked = true

