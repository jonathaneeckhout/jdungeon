extends ActionLeaf

@onready var flee_behavior := preload("res://scripts/classes/behaviors/JFleeBehavior.gd")
@export var flee_magnitude_min := 300
@export var flee_magnitude_max := 800
var target_reached = false
var target = null
var calmed = false
var dead_ended = false

func tick(actor: Node, blackboard: Blackboard):
	var attacker_global_pos: Vector2 = blackboard.get_value("attacker_global_position")
	if !actor.behavior or actor.behavior.name != "FleeBehavior":
		J.logger.warn("Switched to FleeBheavior" + self.name)
		if actor.behavior:
			actor.behavior.queue_free()
		actor.behavior = flee_behavior.new(flee_direction(attacker_global_pos, actor.global_position))
		actor.behavior.name = "FleeBehavior"
		actor.behavior.actor = actor
		actor.add_child(actor.behavior)
	if not actor.behavior.flee_complete.is_connected(_flee_done):
		actor.behavior.flee_complete.connect(_flee_done)
	if not actor.behavior.dead_end.is_connected(_dead_ended):
		actor.behavior.dead_end.connect(_dead_ended)
	if dead_ended:
		J.logger.warn("DeadEnded")
		dead_ended = false
		actor.behavior.flee_target = -actor.behavior.flee_target
	if calmed:
		J.logger.warn("Calmed Down")
		calmed = false
		actor.velocity = Vector2.ZERO
		actor.behavior.flee_complete.disconnect(_flee_done)
		actor.behavior.dead_end.disconnect(_dead_ended)
		return SUCCESS
	return RUNNING

func flee_direction(attacker_global_pos: Vector2, actor_global_pos: Vector2) -> Vector2:
	J.logger.warn("Running from " + str(attacker_global_pos))
	var direction := -(attacker_global_pos - actor_global_pos).normalized()
	var flee_target = direction * flee_magnitude_max
	J.logger.warn("Flee Target is " + str(flee_target))
	return flee_target

func _flee_done():
	calmed = true

func _dead_ended():
	dead_ended = true
