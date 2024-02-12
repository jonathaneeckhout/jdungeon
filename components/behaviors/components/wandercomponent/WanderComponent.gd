extends Node2D

class_name WanderComponent

## The maximum time the parent can stay stuck
const MAX_COLLIDING_TIME: float = 1.0

# The parent behavior node of this wander component
var _parent: Node = null

# The actor for this wander component
var _target_node: Node = null

# The stats sychronizer used to check if the parent node is dead or not
var _stats_component: StatsSynchronizerComponent = null

# The avoidance ray component is used to detect obstacles ahead
var _avoidance_rays_component: AvoidanceRaysComponent = null

# The minimum time the parent will stay idle
var _min_idle_time: int = 0

# The maximum time the parent will stay idle
var _max_idle_time: int = 0

# The maximum distance the parent should wander off to
var _max_wander_distance: float = 0.0

# Timer used to check how long the parent should stay idle
var _idle_timer: Timer = null

# Timer used to check if the parent is not stuck too long
var _colliding_timer: Timer = null

# Location to which the parent will wander to
var _wander_target: Vector2

# The starting location of the parent, used to move back when a player lured him away
var _starting_postion: Vector2

# Check if you're linked with your parent
var _linked: bool = false

var _path: AStarComponent.AStarPath = null


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

	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	_idle_timer.name = "IdleTimer"
	_idle_timer.timeout.connect(_on_idle_timer_timeout)
	add_child(_idle_timer)

	_colliding_timer = Timer.new()
	_colliding_timer.one_shot = true
	_colliding_timer.name = "CollidingTimer"
	_colliding_timer.wait_time = MAX_COLLIDING_TIME
	_colliding_timer.timeout.connect(_on_colliding_timer_timeout)
	add_child(_colliding_timer)

	# Keep track of the original starting position for later use
	_starting_postion = _target_node.position

	# For now stay at your spawned location
	_wander_target = _starting_postion

	# Start the idle timer once to start the mechanism
	_idle_timer.start(randi_range(_min_idle_time, _max_idle_time))


func _link_parent():
	assert(
		_parent.get("stats_component") != null,
		"The parent behavior should have the stats_component variable"
	)
	_stats_component = _parent.stats_component

	assert(
		_parent.get("avoidance_rays_component") != null,
		"The parent behavior should have the avoidance_rays_component variable"
	)
	_avoidance_rays_component = _parent.avoidance_rays_component

	assert(
		_parent.get("min_idle_time") != null,
		"The parent behavior should have the min_idle_time variable"
	)
	_min_idle_time = _parent.min_idle_time

	assert(
		_parent.get("max_idle_time") != null,
		"The parent behavior should have the max_idle_time variable"
	)
	_max_idle_time = _parent.max_idle_time

	assert(
		_parent.get("max_wander_distance") != null,
		"The parent behavior should have the max_wander_distance variable"
	)
	_max_wander_distance = _parent.max_wander_distance

	_linked = true


func wander():
	# Don't do anything if you're not linked yet with your parent
	if not _linked:
		return

	# If the navigation agent is still going, move towards the next point
	if _path != null and not _path.is_navigation_finished():
		# Get the next path position
		var next_path_position: Vector2 = _path.get_next_path_position(_target_node.position)

		# Calculate the velocity towards this next path position
		_target_node.velocity = (
			_target_node.position.direction_to(next_path_position) * _stats_component.movement_speed
		)

		# Try to move to the next point but avoid any obstacles
		_avoidance_rays_component.move_with_avoidance(_target_node.stats.movement_speed)

		# Check if the parent is stuck or not
		_check_if_stuck()

	# If the idle timer is stopped, restart it to find a new wander location
	elif _idle_timer.is_stopped():
		_idle_timer.start(randi_range(_min_idle_time, _max_idle_time))
		_target_node.velocity = Vector2.ZERO


func _check_if_stuck():
	# Check if there is a collision even after avoidance
	if _target_node.get_slide_collision_count() > 0:
		if _colliding_timer.is_stopped():
			_colliding_timer.start()
	# Stop the avoidance timer
	else:
		if !_colliding_timer.is_stopped():
			_colliding_timer.stop()


## Find a random location around the origin position within a maximum distance
static func find_random_spot(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _on_idle_timer_timeout():
	# Find a new location to wander to
	_wander_target = WanderComponent.find_random_spot(_starting_postion, _max_wander_distance)
	_path = _target_node.multiplayer_connection.map.astar.get_astar_path(
		_target_node.position, _wander_target
	)


func _on_colliding_timer_timeout():
	# Find a new location to wander to
	_wander_target = WanderComponent.find_random_spot(_starting_postion, _max_wander_distance)
	_path = _target_node.multiplayer_connection.map.astar.get_astar_path(
		_target_node.position, _wander_target
	)
