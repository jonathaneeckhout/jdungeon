extends Node2D

class_name AttackAndWanderBehaviorComponent

## When aggroed, the time between 2 path search
const TIME_BEFORE_NEXT_PATH_SEARCH: float = 1.0

## The stats sychronizer used to check if the parent node is dead or not
@export var stats_component: StatsSynchronizerComponent

## The action synchronzer used to sync the attack animation to other players
@export var action_synchronizer: ActionSynchronizerComponent

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

# Timer used to delay searching for a new path. Mainly used to save some cpu power
var _search_path_timer: Timer = null

# Timer to keep track of the timeout between two attacks
var _attack_timer: Timer = null

# Raycast used to check if the current target is in line of sight
var _line_of_sight_raycast: RayCast2D = null

# The navigation agent used to find a new location
@onready var _navigation_agent: NavigationAgent2D = $NavigationAgent2D

# The component used to handle the wandering
@onready var _wander_component: WanderComponent = $WanderComponent

# The avoidance ray component is used to detect obstacles ahead
@onready var avoidance_rays_component: AvoidanceRaysComponent = $AvoidanceRaysComponent


func _ready():
	# This node should only run the server side
	if not G.is_server():
		set_physics_process(false)
		queue_free()

	_target_node = get_parent()

	if _target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return
	if _target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

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


func _init_timers():
	_search_path_timer = Timer.new()
	_search_path_timer.one_shot = true
	_search_path_timer.name = "SearchPathTimer"
	_search_path_timer.wait_time = TIME_BEFORE_NEXT_PATH_SEARCH
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
		_wander_component.wander()


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
			avoidance_rays_component.move_with_avoidance(_target_node.stats.movement_speed)
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
				avoidance_rays_component.move_with_avoidance(_target_node.stats.movement_speed)

			# Navigation is finish, let's calculate a new path
			else:
				_navigation_agent.target_position = _current_target.position
	return


func _is_target_in_line_of_sight(target: Node2D) -> bool:
	# Set the direction of the ray
	_line_of_sight_raycast.target_position = target.position - _target_node.position
	# Update the raycast
	_line_of_sight_raycast.force_raycast_update()

	return not _line_of_sight_raycast.is_colliding()


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
