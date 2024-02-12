extends Node2D

class_name FleeComponent

## The maximum time the parent can stay stuck
const MAX_COLLIDING_TIME: float = 1.0

## The time the parent runs away after being hit
const FLEE_TIME: float = 5.0

## Bool variable indicating that the parent is fleeing from someone
var fleeing: bool = false

# The parent behavior node of this wander component
var _parent: Node = null

# The actor for this wander component
var _target_node: Node = null

# The stats sychronizer used to check if the parent node is dead or not
var _stats_component: StatsSynchronizerComponent = null

# The avoidance ray component is used to detect obstacles ahead
var _avoidance_rays_component: AvoidanceRaysComponent = null

# How much the speed of the parent should increase when fleeing
var _flee_speed_boost: float = 3.0

# Timer used to check how long the parent should flee
var _flee_timer: Timer = null

# Check if you're linked with your parent
var _linked: bool = false

# The entity who attacked the parent
var _attacker: CharacterBody2D = null


func _ready():
	# Get the parent node
	_parent = get_parent()

	# This Node should run one level deeper than the behavior component
	_target_node = _parent.get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This node should only run the server side
	if not _target_node.multiplayer_connection.is_server():
		set_physics_process(false)
		queue_free()

	# Call this one deferred to give the time to the parent to add all it's childs
	_link_parent.call_deferred()

	_flee_timer = Timer.new()
	_flee_timer.one_shot = true
	_flee_timer.wait_time = FLEE_TIME
	_flee_timer.name = "FleeTimer"
	_flee_timer.timeout.connect(_on_flee_timer_timeout)
	add_child(_flee_timer)


func _link_parent():
	assert(
		_parent.get("stats_component") != null,
		"The parent behavior should have the stats_component variable"
	)
	_stats_component = _parent.stats_component

	_stats_component.got_hurt.connect(_on_got_hurt)

	assert(
		_parent.get("avoidance_rays_component") != null,
		"The parent behavior should have the avoidance_rays_component variable"
	)
	_avoidance_rays_component = _parent.avoidance_rays_component

	assert(
		_parent.get("flee_speed_boost") != null,
		"The parent behavior should have the flee_speed_boost variable"
	)
	_flee_speed_boost = _parent.flee_speed_boost

	_linked = true


## If fleeing is true, run the oposite direction of the attacker
func flee():
	# Don't do anything if you're not linked yet with your parent
	if not _linked:
		return

	# This component should not do anything if not fleeing
	if not fleeing:
		return

	# The _attacker could not be found, it likely despawned.
	if not is_instance_valid(_attacker):
		return

	# Calculate the speed while fleeing
	var flee_speed: float = _stats_component.movement_speed * _flee_speed_boost

	# Face the oposite direction of your attacker
	_target_node.velocity = (_attacker.position.direction_to(_target_node.position) * flee_speed)

	# Try to move to the next point but avoid any obstacles
	_avoidance_rays_component.move_with_avoidance(flee_speed)


func _on_flee_timer_timeout():
	# Stop fleeing if this timer timeouts
	fleeing = false

	# Reset the attacker
	_attacker = null


func _on_got_hurt(from: String, _damage: int):
	_attacker = _target_node.multiplayer_connection.map.get_entity_by_name(from)

	# Ignore if we can't find the attacker
	if _attacker == null:
		GodotLogger.warn("Couldn't find attacker %s" % from)
		return

	# This triggers the fleeing
	fleeing = true

	# Start the flee timer to check how long the parent should flee
	_flee_timer.start()
