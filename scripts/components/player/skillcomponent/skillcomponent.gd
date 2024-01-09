extends Node2D

class_name SkillComponent
## Takes care of handling skills, their effects, cooldowns and costs, as well as the drawing of hitboxes for player feedback.

#TODO:
#Prepare an UI element to check skills

const COMPONENT_NAME: String = "skill_component"

enum SKILL_ATTEMPT_RESULT { OK, INSUFFICIENT_ENERGY, OUT_OF_RANGE, COOLDOWN_RUNNING }

const COOLDOWN_TIMER_INTERVAL: float = 0.1

# All of these signals are meant for local use, they should not affect any networking related stuff.
# Signal indicating that a skill used successfully
signal skill_successful_usage(skill: SkillComponentResource)

# Signal indicating that a skill used failed
signal skill_failed_usage(skill: SkillComponentResource)

# Signal indicating that a skill usage was attempted
signal skill_attempt_result(result: SKILL_ATTEMPT_RESULT)

# Signal indicating that a skill was select
signal skill_selected(skill: SkillComponentResource)

# Signal indicating that a skill used at a certain index
signal skill_index_selected(index: int)

# Signal indicating that the cooldown of a skill changed
signal skill_cooldown_updated(skill: String, time: float)

# Signal indicating that a skill was used immediately after being selected (example: heal skill)
signal skill_cast_on_select_selected(skill: SkillComponentResource)

## Signal indicating that something about the skills have changed
signal skills_changed
@export_group("Node References")
@export var stats_component: StatsSynchronizerComponent
@export var player_synchronizer: PlayerSynchronizer

@export_group("Visual Preferences")
## Color for the area where the skill will hit.
@export var color_hitbox: Color = Color.AQUA / 2
## Color for the hitbox when the skill cannot be used.
@export var color_hitbox_unusable: Color = Color.FIREBRICK / 2
## Color for the hitbox when the cursor is out of range
@export var color_hitbox_out_of_range: Color = Color.MISTY_ROSE / 2
## Color for the area drawn around the user when the skill is selected. Determining how far the skill can be used.
@export var color_range: Color = Color.GREEN_YELLOW / 3
## Range is from -1 and upwards, does not affect polygons.
@export var hitbox_line_thickness: float = 2
## Does not affect polygons.
@export var hitbox_line_antialiasing: bool = false
## Only used for CircleShape2D hitboxes. Determines the definition of the drawn circle outline
@export var hitbox_circle_outline_point_count: int = 45

@export_group("Main Functionality")
## The array containing all the skills
@export var skills: Array[SkillComponentResource]

## The skill that is currently select and can be used
@export var _skill_current: SkillComponentResource:
	set(val):
		# Set the value
		if val is SkillComponentResource:
			_skill_current = val.duplicate()

		# Stop here if it is a null value
		else:
			_skill_current = null
			skill_index_selected.emit(-1)
			skill_selected.emit(null)
			return

		# Throw an error if this skill is not present in this SkillComponent
		if not _skill_current.skill_class in get_skills_classes():
			GodotLogger.error(
				"The skill of class {0} does not belong to this component".format(
					[_skill_current.skill_class]
				)
			)
			return

		# Check at which index the skill is mapped
		var skill_index: int = skills.find(_skill_current)

		skill_index_selected.emit(skill_index)

		skill_selected.emit(_skill_current)

# This variable is used to check if this component should accept input events on the client-side
@export var accepting_input: bool = true

# Dict that keeps track of all skills that are on cooldown
var _cooldown_dict: Dictionary

# Direct space to use to query which targets are under the skill area
var _direct_space: PhysicsDirectSpaceState2D

# This serves as the parent node on which the component will take effect.
var _target_node: CharacterBody2D = null


func _ready() -> void:
	# Common-side logic

	#Do not connect if not debug, for performance reasons.
	if OS.is_debug_build():
		skill_attempt_result.connect(_print_skill_attempt_result)

	# set the _target_node
	if not _init_target_node():
		GodotLogger.error("Failed to initialize _target_node")
		return

	# Timer used to check the skills cooldown in an interval
	var cooldown_timer: Timer = Timer.new()
	cooldown_timer.name = "CooldownTimer"
	cooldown_timer.timeout.connect(cooldown_process)
	add_child(cooldown_timer)

	# Server-side logic
	if G.is_server():
		# Don't handle input on server side
		set_process_input(false)

		# The process call is used to trigger a redraw, thus only needed on the client side
		set_process(false)

		skills_changed.connect(sync_skills.bind(_target_node.peer_id))

	# Client-side logic
	else:
		# Wait until the connection is ready to synchronize stats
		if not multiplayer.has_multiplayer_peer():
			await multiplayer.connected_to_server

		# Wait an additional frame so others can get set.
		await get_tree().process_frame

		# Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		# Initially fetch the skills
		G.sync_rpc.skillcomponent_sync_skills.rpc_id(1, _target_node.get_name())

	# Common side logic

	# Start the cooldown timer
	cooldown_timer.start(COOLDOWN_TIMER_INTERVAL)

	# Connect to the skill_used signal to detect when a skill is used
	player_synchronizer.skill_used.connect(_on_skill_used)


func _init_target_node() -> bool:
	# Get the parent node
	_target_node = get_parent()

	# The peer_id is needed to have rpc working
	if _target_node.get("peer_id") == null:
		GodotLogger.error("_target_node does not have the peer_id variable")
		return false

	# Register the component in the parent's component_list
	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	return true


# Skill selection is local
func _input(event: InputEvent) -> void:
	if not accepting_input:
		return

	if event.is_action_pressed("j_slot_deselect"):
		_select_skill_by_index(-1)

	elif event.is_action_pressed("j_slot1"):
		_select_skill_by_index(0)
	elif event.is_action_pressed("j_slot2"):
		_select_skill_by_index(1)
	elif event.is_action_pressed("j_slot3"):
		_select_skill_by_index(2)
	elif event.is_action_pressed("j_slot4"):
		_select_skill_by_index(3)
	elif event.is_action_pressed("j_slot5"):
		_select_skill_by_index(4)


# This function is only triggered on the client-side
func _process(_delta: float) -> void:
	queue_redraw()


func _draw():
	# Don't draw on the server side
	if G.is_server():
		return

	# Don't handle invalid skills
	if not _skill_current is SkillComponentResource:
		return

	# The hitbox shape should be bigger than 0 to be able to draw it
	if _skill_current.hitbox_shape.is_empty():
		return

	# Draw the range of the skill
	if Global.debug_mode:
		_draw_range()

	# Draw the hitbox of the skill
	_draw_hitbox()


# Draw a circle around the player indicating what the range is
# This function should only be ran on the client-side
func _draw_range():
	draw_circle(Vector2.ZERO, _skill_current.hit_range, color_range)


# Draw a shape indicating the area the skill has effect on
# This function should only be ran on the client-side
func _draw_hitbox(local_point: Vector2 = to_local(player_synchronizer.mouse_global_pos)):
	var shape: Shape2D

	# If the skill should rotate, pass it as an argument
	if _skill_current.hitbox_rotate_shape:
		shape = get_collision_shape(_target_node.global_position.angle_to_point(local_point))
	else:
		shape = get_collision_shape(0.0)

	# Color selection
	var color_used: Color

	# When a skill is on cooldown or you don't have enough energy, display the hitbox red
	if _is_skill_cooling_down(_skill_current) or not _is_skill_energy_affordable(_skill_current):
		color_used = color_hitbox_unusable

	# When trying to use a skill out of skill range, display it rose
	elif not _is_skill_target_within_range(
		_skill_current, _target_node.position, player_synchronizer.mouse_global_pos
	):
		color_used = color_hitbox_out_of_range

	# If the skill can be used and is not on cooldown, draw it it's normal color
	else:
		color_used = color_hitbox

	# Draw the shape if it's a circle
	if shape is CircleShape2D:
		draw_circle(local_point, shape.radius, color_used * 0.35)
		draw_arc(
			local_point,
			shape.radius,
			0,
			TAU,
			hitbox_circle_outline_point_count,
			color_used,
			hitbox_line_thickness,
			hitbox_line_antialiasing
		)

	elif shape is SegmentShape2D:
		var points: Array[Vector2] = [shape.a + local_point, shape.b + local_point]
		draw_line(points[0], points[1], color_used, hitbox_line_thickness, hitbox_line_antialiasing)

	# Draw the shape if it's a convex polygon
	elif shape is ConvexPolygonShape2D:
		# A minimal shape should have at least 3 points
		assert(shape.points.size() >= 3)

		var polygon: PackedVector2Array = []

		#Shift polygon points towards the mouse's position
		for point in shape.points:
			polygon.append(point + local_point)

		draw_colored_polygon(polygon, color_used)


# Progresses the cooldown by 0.1 at a time.
func cooldown_process():
	for skillClass in _cooldown_dict:
		assert(_cooldown_dict.get(skillClass) is float)

		var newCooldown: float = move_toward(get_cooldown_time_left(skillClass), 0, 0.1)

		cooldown_set_time_left(skillClass, newCooldown)

	while _cooldown_dict.values().has(0 as float):
		_cooldown_dict.erase(_cooldown_dict.find_key(0 as float))


# Add a skill
func add_skill(skill_class: String):
	#Do not allow duplicates
	if skill_class in get_skills_classes():
		if Global.debug_mode:
			GodotLogger.info("Rejected duplicate skill '{0}'".format([skill_class]))
		return

	var skill_found: SkillComponentResource = J.skill_resources.get(skill_class, null)

	if skill_found is SkillComponentResource:
		skills.append(skill_found.duplicate())

		skills_changed.emit()


# Remove a skill
func remove_skill(skill_class: String):
	for skill in skills:
		if skill.skill_class == skill_class:
			skills.erase(skill)
			skills_changed.emit()
			return


func clear_skills():
	skills.clear()
	skills_changed.emit()


# Select a skill using its index
func _select_skill_by_index(index: int):
	# The index can range from -1 to size()-1
	if not (index >= -1 and index < skills.size()):
		# A wrong value does nothing.
		return

	# If -1 OR it was already selected, treat it as a deselection attempt.
	# It is important to check if _skill_current isn't null
	if index == -1 or (_skill_current and get_skill_current_class() == _skill_current.skill_class):
		_deselect_skill()
		return

	# Otherwise, change the skill properly
	_skill_current = skills[index]

	# This must be separate from the _skill_current setter to avoid infinite loops
	if _skill_current.cast_on_select:
		skill_cast_on_select_selected.emit(_skill_current)


# Can only find skills inside this component, fails otherwise.
func _select_skill_by_class(skill_class: String):
	for skill in skills:
		if skill.skill_class == skill_class:
			_skill_current = skill

			# This must be separate from the _skill_current setter to avoid infinite loops
			if _skill_current.cast_on_select:
				skill_cast_on_select_selected.emit(_skill_current)

			return

	GodotLogger.warn('Could not find "{0}" skill in this component'.format([skill_class]))


# Deselect a skill
func _deselect_skill():
	_skill_current = null


# Use a certain skill at a certain position
func _use_skill_at_position(global_point: Vector2, skill_class: String = get_skill_current_class()):
	# Duplicate the resource
	var skill_used: SkillComponentResource = J.skill_resources[skill_class].duplicate()

	# Set the current skill to the one that is being used
	_skill_current = skill_used

	# Prepare the usage info.
	var skill_usage_Info := SkillUseInfo.new()
	skill_usage_Info.user = _target_node

	# Find the targets under the skill area
	skill_usage_Info.targets = _get_targets_under_current_skill(global_point)
	skill_usage_Info.position_target_global = global_point

	# Check if we can use the skill at the given position
	var skill_use_result: SKILL_ATTEMPT_RESULT = _validate_skill_result(
		skill_used, skill_usage_Info
	)

	# If we can use the skill we do
	if skill_use_result == SKILL_ATTEMPT_RESULT.OK:
		# The actual effect of the skill only needs to be done on the server-side
		if G.is_server():
			# Perform the skill's effect on the targets
			skill_used.effect(skill_usage_Info)

			# Use up energy needed for the skill
			stats_component.energy_recovery(
				skill_usage_Info.user.get_name(), -skill_used.energy_usage
			)

		# Emit success signal
		skill_successful_usage.emit(skill_used)

		# Start cooldown on both the server and client-side
		cooldown_set_time_left(skill_used.skill_class, skill_used.cooldown)
	else:
		# Emit failed signal
		skill_failed_usage.emit(skill_used)

	# Broadcast the result regardless of success
	skill_attempt_result.emit(skill_use_result)

	# Cast_on_select skills should never stay selected.
	if skill_used.cast_on_select:
		_deselect_skill()


# Get the target that are situated under the current skill
func _get_targets_under_current_skill(global_pos: Vector2) -> Array[Node]:
	var shape_parameters := PhysicsShapeQueryParameters2D.new()

	# Use the hitbox areas to detect collision
	shape_parameters.collide_with_areas = true
	shape_parameters.collide_with_bodies = false

	# If the hitbox should be rotated, do so.
	if _skill_current.hitbox_rotate_shape:
		shape_parameters.shape = get_collision_shape(
			_target_node.global_position.angle_to_point(global_pos)
		)

	else:
		shape_parameters.shape = get_collision_shape(0.0)

	# Move to target location
	shape_parameters.transform = shape_parameters.transform.translated(global_pos)

	# Set the correct collisions
	shape_parameters.collision_mask = _skill_current.collision_mask

	# Exclude the user if this skill is not meant to target them. (Candidate for removal, somewhat unnecessary)
	if not _skill_current.hitbox_hits_user:
		shape_parameters.exclude = [_target_node.get_rid()]

	# Get the current physics space to use
	_direct_space = _target_node.get_world_2d().direct_space_state

	# Get and store all targets found
	var collisions: Array[Dictionary] = _direct_space.intersect_shape(shape_parameters)
	var targets: Array[Node] = []

	for coll in collisions:
		targets.append(coll.get("collider").get_parent())

	# Custom filter per skill, defaults to allow everything
	targets.filter(_skill_current._target_filter)

	return targets


## Fetch the collision shape of the current selected skill
func get_collision_shape(user_rotation: float) -> Shape2D:
	var shape: Shape2D
	if _skill_current.hitbox_shape.is_empty():
		shape = CircleShape2D.new()
		shape.radius = 0
		return shape

	# If it is only 1 point, treat it as a circle
	if _skill_current.hitbox_shape.size() == 1:
		shape = CircleShape2D.new()

		shape.radius = _skill_current.hitbox_shape[0].length()

	#If 2, it is a line
	elif _skill_current.hitbox_shape.size() == 2:
		shape = SegmentShape2D.new()
		shape.a = _skill_current.hitbox_shape[0].rotated(user_rotation)
		shape.b = _skill_current.hitbox_shape[1].rotated(user_rotation)

	# Otherwise treat it as a polygon
	else:
		shape = ConvexPolygonShape2D.new()

		var newPoints: PackedVector2Array = []

		for point in _skill_current.hitbox_shape:
			newPoints.append(point.rotated(user_rotation))

		shape.points = newPoints

		assert(shape.points.size() >= 3)

	return shape


## Get the collision mask of the current selected skill
func get_collision_layer() -> int:
	assert(_skill_current.collision_mask != 0)
	return _skill_current.collision_mask


## Get the time left from the cooldown
func get_cooldown_time_left(skill_class: String) -> float:
	assert(skill_class != "")
	return _cooldown_dict.get(skill_class, 0 as float)


# Sets cooldowns for skills per class
func cooldown_set_time_left(skill_class: String, time: float):
	_cooldown_dict[skill_class] = time
	skill_cooldown_updated.emit(skill_class, time)


## Get the class of the current selected skill
func get_skill_current_class() -> String:
	if _skill_current is SkillComponentResource:
		return _skill_current.skill_class
	else:
		return ""


## Get all the skill classes
func get_skills_classes() -> Array[String]:
	var arr: Array[String] = []
	for skill in skills:
		arr.append(skill.skill_class)
	return arr


## Check if the skill is present
func is_skill_present(skill_class: String) -> bool:
	for skill in skills:
		if skill.skill_class == skill_class:
			return true
	return false


# Validate if the result of the skill in ok
func _validate_skill_result(
	skill: SkillComponentResource, use_info: SkillUseInfo
) -> SKILL_ATTEMPT_RESULT:
	# Check if the skill is cooling down
	if _is_skill_cooling_down(skill):
		return SKILL_ATTEMPT_RESULT.COOLDOWN_RUNNING

	# Check if the target node has enough energy
	if not _is_skill_energy_affordable(skill):
		return SKILL_ATTEMPT_RESULT.INSUFFICIENT_ENERGY

	# Check if skill target position is in range
	if not _is_skill_target_within_range(
		skill, use_info.user.global_position, use_info.position_target_global
	):
		return SKILL_ATTEMPT_RESULT.OUT_OF_RANGE

	return SKILL_ATTEMPT_RESULT.OK


# Check if the skill is on cooldown
func _is_skill_cooling_down(skill: SkillComponentResource) -> bool:
	return not is_zero_approx(get_cooldown_time_left(skill.skill_class))


# Check if we have enough energy
func _is_skill_energy_affordable(skill: SkillComponentResource) -> bool:
	return stats_component.energy >= skill.energy_usage


# Check if the target is in range for the skill
func _is_skill_target_within_range(
	skill: SkillComponentResource, userPosGlobal: Vector2, targetPosGlobal: Vector2
):
	return userPosGlobal.distance_to(targetPosGlobal) <= skill.hit_range


# Serialize the skills into a json object
func to_json() -> Dictionary:
	var output: Dictionary = {}
	var slot_idx: int = 0

	for skill in skills:
		output[slot_idx] = skill.skill_class

		slot_idx += 1

	return output


# Deserialize the skills from a json
func from_json(data: Dictionary) -> bool:
	# Clear the current skills
	skills.clear()

	for slot_idx in data:
		# Check if the datafield is a string
		if not data[slot_idx] is String:
			GodotLogger.warn(
				'Failed to load skills from data, missing "skill_class" for slot {0}'.format(
					[str(slot_idx)]
				)
			)

			return false

		# Add the skill resource to the list of skills

		add_skill(data[slot_idx])

		assert(skills[slot_idx] is SkillComponentResource)

	return true


## Send back the skill data towards the client
## This function should only be called on the server-side
func sync_skills(id: int):
	G.sync_rpc.skillcomponent_sync_response.rpc_id(id, _target_node.get_name(), to_json())


## Load the network response from the sync
## This function  should only be called on client-side
func sync_response(skills_data: Dictionary):
	from_json(skills_data)


# Debug function that prints usefull information of the current selected skill
func _print_skill_attempt_result(result: SKILL_ATTEMPT_RESULT):
	# Only handle this function in debug mode
	if not Global.debug_mode:
		return

	# Print usefull debug information about the skill used
	print(
		(
			"'"
			+ _target_node.get_name()
			+ "' attempted to use skill '"
			+ _skill_current.skill_class
			+ "' with result: '"
			+ SKILL_ATTEMPT_RESULT.find_key(result)
			+ "' on instance "
			+ get_window().title
		)
	)


# Callback function when a skill is actually used by a player
func _on_skill_used(where: Vector2, skill_class: String):
	_use_skill_at_position(where, skill_class)
