extends Node2D

class_name AggroComponent

## When aggroed, the time between 2 path search
const TIME_BEFORE_NEXT_PATH_SEARCH: float = 1.0

## The current targeted player
var current_target: Player = null

# The parent behavior node of this wander component
var _parent: Node = null

# The actor for this wander component
var _target_node: Node = null

# The stats sychronizer used to check if the parent node is dead or not
var _stats_component: StatsSynchronizerComponent = null

# The action synchronzer used to sync the attack animation to other players
var _action_synchronizer: ActionSynchronizerComponent = null

# The avoidance ray component is used to detect obstacles ahead
var _avoidance_rays_component: AvoidanceRaysComponent = null

# This is the area used to detect players
var _aggro_area: Area2D = null

# Check if you're linked with your parent
var _linked: bool = false

# The players who are in aggro range
var _players_in_aggro_range: Array[Player] = []

# Timer used to delay searching for a new path. Mainly used to save some cpu power
var _search_path_timer: Timer = null

# Timer to keep track of the timeout between two attacks
var _attack_timer: Timer = null

# Raycast used to check if the current target is in line of sight
var _line_of_sight_raycast: RayCast2D = null

var _path: AStarComponent.AStarPath = null


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the parent node

	# This Node should run one level deeper than the behavior component

	# Call this one deferred to give the time to the parent to add all it's childs
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

	# Init the line of sight raycast
	_line_of_sight_raycast = RayCast2D.new()
	_line_of_sight_raycast.name = "LineOfSightRaycast"
	_line_of_sight_raycast.collision_mask = J.PHYSICS_LAYER_WORLD
	add_child(_line_of_sight_raycast)


func _link_parent():
	assert(
		_parent.get("stats_component") != null,
		"The parent behavior should have the stats_component variable"
	)
	_stats_component = _parent.stats_component

	assert(
		_parent.get("action_synchronizer") != null,
		"The parent behavior should have the action_synchronizer variable"
	)
	_action_synchronizer = _parent.action_synchronizer

	assert(
		_parent.get("avoidance_rays_component") != null,
		"The parent behavior should have the avoidance_rays_component variable"
	)
	_avoidance_rays_component = _parent.avoidance_rays_component

	assert(
		_parent.get("aggro_area") != null, "The parent behavior should have the aggro_area variable"
	)
	_aggro_area = _parent.aggro_area

	# Connect to the aggro area to detect closeby players
	_aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	_aggro_area.body_exited.connect(_on_aggro_area_body_exited)

	_linked = true


func aggro():
	# Don't do anything if you're not linked yet with your parent
	if not _linked:
		return

	# If the player is close enough, hit him
	if _target_node.position.distance_to(current_target.position) < _stats_component.attack_range:
		# Don't do anything if the attack timer is running, this means your attack is still on timeout
		if !_attack_timer.is_stopped():
			return

		# We shall leave the dead alone
		if current_target.stats.is_dead:
			return

		# Generate a random damage between the parents's min and max attack power
		var damage: int = randi_range(
			_stats_component.attack_power_min, _stats_component.attack_power_max
		)

		# This is the call that actually hurts the target
		current_target.stats.hurt(_target_node, damage)

		# Synchronize to other players that the parent attacked
		_action_synchronizer.attack(_target_node.position.direction_to(current_target.position))

		# Start the timer so that the parent needs to wait for this timer to stop before performing another attack
		_attack_timer.start(_stats_component.attack_speed)

	# If the player is out of range, move towards him
	else:
		# If the target is in line of sight, move towards it
		if _is_target_in_line_of_sight(current_target):
			# Calculate the velocity towards the current target
			_target_node.velocity = (
				_target_node.position.direction_to(current_target.position)
				* _stats_component.movement_speed
			)

			# Try to move to the next point but avoid any obstacles
			_avoidance_rays_component.move_with_avoidance(_target_node.stats.movement_speed)
		else:
			# If the target's position has changed and the search path timer is not running, calculate a new path towards the target
			if _search_path_timer.is_stopped():
				# This will trigger a new calculation of the navigation path
				_path = _target_node.multiplayer_connection.map.astar.get_astar_path(
					_target_node.position, current_target.position
				)
				# Start the search path timer to limit the amount of navigation path searches
				_search_path_timer.start()

			# Navigate to the next path position
			if _path != null and not _path.is_navigation_finished():
				# Get the next path position
				var next_path_position: Vector2 = _path.get_next_path_position(
					_target_node.position
				)

				# Calculate the velocity towards this next path position
				_target_node.velocity = (
					_target_node.position.direction_to(next_path_position)
					* _stats_component.movement_speed
				)

				# Try to move to the next point but avoid any obstacles
				_avoidance_rays_component.move_with_avoidance(_target_node.stats.movement_speed)

			# Navigation is finish, let's calculate a new path
			else:
				_path = _target_node.multiplayer_connection.map.astar.get_astar_path(
					_target_node.position, current_target.position
				)
	return


func _is_target_in_line_of_sight(target: Node2D) -> bool:
	# Set the direction of the ray
	_line_of_sight_raycast.target_position = target.position - _target_node.position
	# Update the raycast
	_line_of_sight_raycast.force_raycast_update()

	return not _line_of_sight_raycast.is_colliding()


func select_first_alive_target():
	current_target = null

	for player: Player in _players_in_aggro_range:
		if not player.stats.is_dead:
			current_target = player


func _on_aggro_area_body_entered(body: Node2D):
	assert(
		body.entity_type == J.ENTITY_TYPE.PLAYER,
		"Only players should be allowed to be present in this physics layer"
	)
	if not _players_in_aggro_range.has(body):
		_players_in_aggro_range.append(body)

		# If you're not targetting anything yet, pick the first one available
		if not current_target:
			select_first_alive_target()


func _on_aggro_area_body_exited(body: Node2D):
	assert(
		body.entity_type == J.ENTITY_TYPE.PLAYER,
		"Only players should be allowed to be present in this physics layer"
	)
	if _players_in_aggro_range.has(body):
		if current_target == body:
			current_target = null

		_players_in_aggro_range.erase(body)
