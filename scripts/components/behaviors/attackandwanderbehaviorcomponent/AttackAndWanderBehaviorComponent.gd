extends Node2D

## The maximum time the parent can stay stuck
const MAX_COLLIDING_TIME: float = 1.0

## When aggroed, the time between 2 path search
const TIME_BEFORE_NEXT_PATH_SEARCH: float = 1.0

## The stats sychronizer used to check if the parent node is dead or not
@export var stats_component: StatsSynchronizerComponent

## The action synchronzer used to sync the attack animation to other players
@export var action_synchronizer: ActionSynchronizerComponent

## The avoidance ray component is used to detect obstacles ahead
@export var avoidance_rays_component: AvoidanceRaysComponent

## This is the area used to detect players
@export var aggro_area: Area2D = null

## The minimum time the parent will stay idle
@export var min_idle_time: int = 3

## The maximum time the parent will stay idle
@export var max_idle_time: int = 10

## The maximum distance the parent should wander off to
@export var max_wander_distance: float = 256.0

# The parent node
var _target_node: Node

# The players who are in aggro range
var _players_in_aggro_range: Array[Player] = []

# The current targeted player
var _current_target: Player = null

# Timer used to check how long the parent should stay idle
var _idle_timer: Timer = null

# Timer used to check if the parent is not stuck too long
var _colliding_timer: Timer = null

# Timer used to delay searching for a new path. Mainly used to save some cpu power
var _search_path_timer: Timer = null

# Timer to keep track of the timeout between two attacks
var _attack_timer: Timer = null

# Raycast used to check if the current target is in line of sight
var _line_of_sight_raycast: RayCast2D = null

# Location to which the parent will wander to
var _wander_target: Vector2

# The starting location of the parent, used to move back when a player lured him away
var _starting_postion: Vector2

# The navigation agent used to find a new location
@onready var _navigation_agent: NavigationAgent2D = $NavigationAgent2D


func _ready():
	_target_node = get_parent()

	if _target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return
	if _target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	# This node should only run the server side
	if not G.is_server():
		set_physics_process(false)
		queue_free()

	# Keep track of the original starting position for later use
	_starting_postion = _target_node.position

	# For now stay at your spawned location
	_wander_target = _starting_postion

	# Connect to the aggro area to detect closeby players
	aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	aggro_area.body_exited.connect(_on_aggro_area_body_exited)

	# Init the timers
	_init_timers()

	# Init the line of sight raycast
	_line_of_sight_raycast = RayCast2D.new()
	_line_of_sight_raycast.name = "LineOfSightRaycast"
	_line_of_sight_raycast.collision_mask = J.PHYSICS_LAYER_WORLD
	add_child(_line_of_sight_raycast)

	# Start the idle timer once to start the mechanism
	_idle_timer.start(randi_range(min_idle_time, max_idle_time))


func _init_timers():
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

	_search_path_timer = Timer.new()
	_search_path_timer.one_shot = true
	_search_path_timer.name = "CollidingTimer"
	_search_path_timer.wait_time = MAX_COLLIDING_TIME
	add_child(_search_path_timer)

	# Create a new timer to keep track of the time between attacks
	_attack_timer = Timer.new()
	_attack_timer.name = "AttackTimer"
	_attack_timer.one_shot = true
	add_child(_attack_timer)


func _physics_process(_delta: float):
	_behavior()


func _behavior():
	# If the parent node is dead, don't do anything
	if stats_component.is_dead:
		_target_node.velocity = Vector2.ZERO
		return

	# Don't aggro if the player is dead
	elif _current_target and _current_target.stats.is_dead:
		# Remove the player from the aggro buffer
		_players_in_aggro_range.erase(_current_target)

		# For now pick the first other player in your aggro range
		if _players_in_aggro_range.size() > 0:
			_current_target = _players_in_aggro_range[0]

		# Clear the current target if there isn't any other player
		else:
			_current_target = null

	# If a player is in range, go after him
	elif _current_target:
		_handle_aggro()

	# If no player is in range, wander around
	else:
		_handle_wandering()


func _handle_aggro():
	# If the player is close enough, hit him
	if _target_node.position.distance_to(_current_target.position) < stats_component.attack_range:
		# Don't do anything if the attack timer is running, this means your attack is still on timeout
		if !_attack_timer.is_stopped():
			return

		# We shall leave the dead alone
		if _current_target.stats.is_dead:
			return

		# Generate a random damage between the parents's min and max attack power
		var damage: int = randi_range(
			stats_component.attack_power_min, stats_component.attack_power_max
		)

		# This is the call that actually hurts the target
		_current_target.stats.hurt(_target_node, damage)

		# Synchronize to other players that the parent attacked
		action_synchronizer.attack(_target_node.position.direction_to(_current_target.position))

		# Start the timer so that the parent needs to wait for this timer to stop before performing another attack
		_attack_timer.start(stats_component.attack_speed)

	# If the player is out of range, move towards him
	else:
		# If the target is in line of sight, move towards it
		if _is_target_in_line_of_sight(_current_target):
			# Calculate the velocity towards the current target
			_target_node.velocity = (
				_target_node.position.direction_to(_current_target.position)
				* stats_component.movement_speed
			)

			# Try to move to the next point but avoid any obstacles
			_move_with_avoidance()
		else:
			# If the target's position has changed and the search path timer is not running, calculate a new path towards the target
			if (
				_navigation_agent.target_position != _current_target.position
				and _search_path_timer.is_stopped()
			):
				# This will trigger a new calculation of the navigation path
				_navigation_agent.target_position = _current_target.position

				# Start the search path timer to limit the amount of navigation path searches
				_search_path_timer.start()

			# Navigate to the next path position
			if not _navigation_agent.is_navigation_finished():
				var next_path_position: Vector2 = _navigation_agent.get_next_path_position()

				# Calculate the velocity towards this next path position
				_target_node.velocity = (
					_target_node.position.direction_to(next_path_position)
					* stats_component.movement_speed
				)

				# Try to move to the next point but avoid any obstacles
				_move_with_avoidance()

			# Navigation is finish, let's calculate a new path
			else:
				_navigation_agent.target_position = _current_target.position
	return


func _handle_wandering():
	# If the navigation agent is still going, move towards the next point
	if not _navigation_agent.is_navigation_finished():
		# Get the next path position
		var next_path_position: Vector2 = _navigation_agent.get_next_path_position()

		# Calculate the velocity towards this next path position
		_target_node.velocity = (
			_target_node.position.direction_to(next_path_position) * stats_component.movement_speed
		)

		# Try to move to the next point but avoid any obstacles
		_move_with_avoidance()

		# Check if the parent is stuck or not
		_check_if_stuck()

	# If the idle timer is stopped, restart it to find a new wander location
	elif _idle_timer.is_stopped():
		_idle_timer.start(randi_range(min_idle_time, max_idle_time))
		_target_node.velocity = Vector2.ZERO


func _move_with_avoidance():
	# Use the avoidance rays to find the optimal velocity
	_target_node.velocity = avoidance_rays_component.find_avoidant_velocity(
		stats_component.movement_speed
	)

	# Actually perform a move and slide
	_target_node.move_and_slide()


func _is_target_in_line_of_sight(target: Node2D) -> bool:
	# Set the direction of the ray
	_line_of_sight_raycast.target_position = target.position - _target_node.position
	# Update the raycast
	_line_of_sight_raycast.force_raycast_update()

	return not _line_of_sight_raycast.is_colliding()


func _check_if_stuck():
	# Check if there is a collision even after avoidance
	if _target_node.get_slide_collision_count() > 0:
		if _colliding_timer.is_stopped():
			_colliding_timer.start()
	# Stop the avoidance timer
	else:
		if !_colliding_timer.is_stopped():
			_colliding_timer.stop()


func _find_random_spot(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _select_traget(target: Node2D):
	if _current_target == null:
		_current_target = target


func _on_aggro_area_body_entered(body: Node2D):
	assert(
		body.entity_type == J.ENTITY_TYPE.PLAYER,
		"Only players should be allowed to be present in this physics layer"
	)
	if not _players_in_aggro_range.has(body):
		_select_traget(body)

		_players_in_aggro_range.append(body)


func _on_aggro_area_body_exited(body: Node2D):
	assert(
		body.entity_type == J.ENTITY_TYPE.PLAYER,
		"Only players should be allowed to be present in this physics layer"
	)
	if _players_in_aggro_range.has(body):
		if _current_target == body:
			_current_target = null

		_players_in_aggro_range.erase(body)


func _on_idle_timer_timeout():
	# Find a new location to wander to
	_wander_target = _find_random_spot(_starting_postion, max_wander_distance)
	_navigation_agent.target_position = _wander_target


func _on_colliding_timer_timeout():
	# Find a new location to wander to
	_wander_target = _find_random_spot(_starting_postion, max_wander_distance)
	_navigation_agent.target_position = _wander_target
