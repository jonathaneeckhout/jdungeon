extends ConditionLeaf

@export var aggro_radius: Area2D = null
@export var should_leash := false
@export var leash_distance: float = 350.0
@onready var reset_timer: Timer = $ResetTimer
var start_combat := false
var in_combat := false
var target: JBody2D = null
var _blackboard: Blackboard


func tick(actor: Node, blackboard: Blackboard):
	if not _blackboard:
		_blackboard = blackboard
	if blackboard.get_value("is_resetting"):
		_reset(actor)
		return FAILURE
	if not reset_timer.timeout.is_connected(_on_reset_timer_timeout):
		reset_timer.timeout.connect(_on_reset_timer_timeout)
	if aggro_radius != null:
		if not aggro_radius.body_entered.is_connected(_on_body_entered):
			aggro_radius.body_entered.connect(_on_body_entered)
	if not actor.synchronizer.got_hurt.is_connected(_on_got_hurt):
		actor.synchronizer.got_hurt.connect(_on_got_hurt)
	if not actor.synchronizer.died.is_connected(_on_actor_died):
		actor.synchronizer.died.connect(_on_actor_died)
	if start_combat:
		in_combat = true
		start_combat = false
		reset_timer.start()
		if not target.synchronizer.died.is_connected(_on_target_died):
			target.synchronizer.died.connect(_on_target_died)
		blackboard.set_value("reset_timer", reset_timer)
		blackboard.set_value("aggro_target", target)
		blackboard.set_value("leash_position", actor.global_position)
		if aggro_radius != null:
			aggro_radius.body_entered.disconnect(_on_body_entered)
	if in_combat:
		var leash_position = blackboard.get_value("leash_position")
		if (
			leash_position != null
			and should_leash
			and leash_position.distance_to(actor.global_position) >= leash_distance
		):
			_reset(actor)
			return FAILURE
		return SUCCESS
	return FAILURE


func _on_body_entered(body: Node2D):
	if target == null:
		start_combat = true
		target = body


func _on_actor_died():
	_blackboard.set_value("is_resetting", true)


func _on_target_died():
	_blackboard.set_value("is_resetting", true)


func _on_got_hurt(from: String, _hp: int, _hp_max: int, _damage: int):
	if in_combat:
		reset_timer.start()
	if target == null:
		start_combat = true
		target = get_node("/root/Root/World/JEntities/JPlayers/" + from)


func _reset(actor: Node):
	if reset_timer.timeout.is_connected(_on_reset_timer_timeout):
		reset_timer.timeout.disconnect(_on_reset_timer_timeout)
	if aggro_radius != null:
		if aggro_radius.body_entered.is_connected(_on_body_entered):
			aggro_radius.body_entered.disconnect(_on_body_entered)
	if actor.synchronizer.got_hurt.is_connected(_on_got_hurt):
		actor.synchronizer.got_hurt.disconnect(_on_got_hurt)
	if actor.synchronizer.died.is_connected(_on_target_died):
		actor.synchronizer.died.disconnect(_on_target_died)
	in_combat = false
	start_combat = false
	target = null


func _on_reset_timer_timeout():
	_blackboard.set_value("is_resetting", true)
