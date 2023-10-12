extends ActionLeaf

@onready var swing_timer := $AttackCooldown

var ready_to_attack := true


func tick(actor: Node, blackboard: Blackboard):
	if not swing_timer.timeout.is_connected(_on_swing_timer_timeout):
		swing_timer.wait_time = actor.stats.attack_speed
		swing_timer.timeout.connect(_on_swing_timer_timeout)
	if ready_to_attack:
		swing_timer.start()
		ready_to_attack = false
		var target: JBody2D = blackboard.get_value("aggro_target")
		actor.attack(target)
		return SUCCESS
	return FAILURE


func _on_swing_timer_timeout():
	ready_to_attack = true
