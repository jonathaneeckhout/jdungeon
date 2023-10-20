extends ActionLeaf

@onready var swing_timer := $AttackCooldown

var ready_to_attack := true


func tick(actor: Node, blackboard: Blackboard):
	assert(actor is JBody2D, "This ticking only works with JBody2D")
	
	if not swing_timer.timeout.is_connected(_on_swing_timer_timeout):
		swing_timer.wait_time = actor.stats.attack_cooldown
		swing_timer.timeout.connect(_on_swing_timer_timeout)
		
	if ready_to_attack:
		swing_timer.start()
		ready_to_attack = false
		var target: JBody2D = blackboard.get_value("aggro_target")
		var reset_timer: Timer = blackboard.get_value("reset_timer")
		reset_timer.start()
		
		var attackInfo := JBody2D.AttackInformation.new()
		attackInfo.target = target
		attackInfo.cooldownExpected = actor.stats.attack_cooldown
		attackInfo.damage = actor.stats.stat_get(JStats.Keys.ATTACK_DAMAGE)
		attackInfo.attacker = actor
		
		actor.attack(attackInfo)
	return SUCCESS


func _on_swing_timer_timeout():
	ready_to_attack = true
