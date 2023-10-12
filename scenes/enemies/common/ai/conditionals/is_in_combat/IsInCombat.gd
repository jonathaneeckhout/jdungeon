extends ConditionLeaf

@export var aggro_radius: Area2D = null
@export var should_leash := false
@export var leash_distance: float = 350.0
@onready var reset_timer: Timer = $ResetTimer
var start_combat := false
var in_combat := false
var target: JBody2D = null


func tick(actor: Node, blackboard: Blackboard):
	if not reset_timer.timeout.is_connected(_on_reset_timer_timeout):
		reset_timer.timeout.connect(_on_reset_timer_timeout)
	if aggro_radius != null:
		if not aggro_radius.body_entered.is_connected(_on_body_entered):
			aggro_radius.body_entered.connect(_on_body_entered)
	if not actor.synchronizer.got_hurt.is_connected(_on_got_hurt):
		actor.synchronizer.got_hurt.connect(_on_got_hurt)
	if start_combat:
		in_combat = true
		start_combat = false
		reset_timer.start()
		blackboard.set_value("aggro_target", target)
		blackboard.set_value("leash_position", actor.global_position)
		if aggro_radius != null:
			aggro_radius.body_entered.disconnect(_on_body_entered)
	if in_combat:
		var leash_position: Vector2 = blackboard.get_value("leash_position")
		if should_leash and leash_position.distance_to(actor.global_position) >= leash_distance:
			return FAILURE
		return SUCCESS
	return FAILURE


func _on_reset_timer_timeout():
	in_combat = false
	target = null


func _on_got_hurt(from: String, _hp: int, _max_hp: int, _damage: int):
	if in_combat:
		reset_timer.start()
	if target == null:
		start_combat = true
		target = get_node("/root/Root/World/JEntities/JPlayers/" + from)


func _on_body_entered(body: Node2D):
	if target == null:
		start_combat = true
		target = body
