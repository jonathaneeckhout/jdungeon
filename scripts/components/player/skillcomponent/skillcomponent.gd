extends Node2D
class_name SkillComponent
## Takes care of handling skills, their effects, cooldowns and costs, as well as the drawing of hitboxes for player feedback.

#TODO:
#Connect player input to skill usage
#Prepare an UI element to check skills

enum SKILL_ATTEMPT_RESULT { OK, INSUFFICIENT_ENERGY, OUT_OF_RANGE, COOLDOWN_RUNNING }

#All of these signals are meant for local use, they should not affect any networking related stuff.
signal skill_successful_usage(skill: SkillComponentResource)
signal skill_failed_usage(skill: SkillComponentResource)
signal skill_attempt_result(result: SKILL_ATTEMPT_RESULT)

signal skill_selected(skill: SkillComponentResource)
signal skill_index_selected(index: int)

signal skill_cooldown_updated(skill: String, time: float)

signal skill_cast_on_select_selected(skill: SkillComponentResource)

signal skills_changed

@export var user: CharacterBody2D

@export_group("Node References")
@export var stats_component: StatsSynchronizerComponent
@export var player_synchronizer: PlayerSynchronizer

@export_group("Visual Preferences")
## Color for the area where the skill will hit.
@export var color_hitbox: Color = Color.AQUA / 2
## Color for the hitbox when the skill cannot be used.
@export var color_hitbox_unusable: Color = Color.FIREBRICK / 2
## Color for the area drawn around the user when the skill is selected. Determining how far the skill can be used.
@export var color_range: Color = Color.GREEN_YELLOW / 3
## Range is from -1 and upwards, does not affect polygons.
@export var hitbox_line_thickness: float = 4
## Does not affect polygons.
@export var hitbox_line_antialiasing: bool = false
## Only used for CircleShape2D hitboxes. Determines the definition of the drawn circle outline
@export var hitbox_circle_outline_point_count: int = 45



@export_group("Main Functionality")
@export var skills: Array[SkillComponentResource]
@export var skill_current: SkillComponentResource:
	set(val):
		#Stop here if it is a null value
		if val is SkillComponentResource:
			skill_current = val.duplicate()
		else:
			skill_current = null
			skill_index_selected.emit(-1)
			skill_selected.emit(null)
			return

		#Throw an error if this skill is not present in this SkillComponent
		if not skill_current.skill_class in get_skills_classes():
			GodotLogger.error(
				"The skill of class {0} does not belong to this component".format(
					[skill_current.skill_class]
				)
			)
			return

		var skillIndex: int = skills.find(skill_current)

		skill_index_selected.emit(skillIndex)
		skill_selected.emit(skill_current)

@export var accepting_input: bool = true

var cooldownDict: Dictionary
var directSpace: PhysicsDirectSpaceState2D


func _ready() -> void:

	#Do not connect if not debug, for performance reasons.
	if OS.is_debug_build():
		skill_attempt_result.connect(print_skill_attempt_result)

	if user.get("component_list") != null:
		user.component_list["skill_component"] = self

	#Cooldown timer
	var cooldownTimer := Timer.new()
	cooldownTimer.timeout.connect(cooldown_process)
	add_child(cooldownTimer)
	cooldownTimer.start(0.1)

	player_synchronizer.skill_used.connect(_on_skill_used)

	if G.is_server():
		return

	#Wait until the connection is ready to synchronize stats
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server

	#Wait an additional frame so others can get set.
	await get_tree().process_frame

	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered

	G.sync_rpc.skillcomponent_sync_skills.rpc_id(1, user.get_name())


#Skill selection is local
func _input(event: InputEvent) -> void:
	if not accepting_input:
		return

	if event.is_action_pressed("j_slot_deselect"):
		skill_select_by_index(-1)

	elif event.is_action_pressed("j_slot1"):
		skill_select_by_index(0)
	elif event.is_action_pressed("j_slot2"):
		skill_select_by_index(1)
	elif event.is_action_pressed("j_slot3"):
		skill_select_by_index(2)
	elif event.is_action_pressed("j_slot4"):
		skill_select_by_index(3)
	elif event.is_action_pressed("j_slot5"):
		skill_select_by_index(4)


func _process(_delta: float) -> void:
	queue_redraw()


#Progresses the cooldown by 0.1 at a time.
func cooldown_process():
	for skillClass in cooldownDict:
		assert(cooldownDict.get(skillClass) is float)
		var newCooldown: float = move_toward(cooldown_get_time_left(skillClass), 0, 0.1)
		cooldown_set_time_left(skillClass, newCooldown)
	while cooldownDict.values().has(0 as float):
		cooldownDict.erase(cooldownDict.find_key(0 as float))


func _draw():
	if not skill_current is SkillComponentResource:
		return

	assert(skill_current.hitbox_shape.size() > 0)

	draw_range()
	draw_hitbox()


func draw_range():
	draw_circle(Vector2.ZERO, skill_current.hit_range, color_range)


func draw_hitbox(localPoint: Vector2 = to_local(player_synchronizer.mouse_global_pos)):
	var shape: Shape2D
	if skill_current.hitbox_rotate_shape:
		shape = get_collision_shape(user.global_position.angle_to_point(localPoint))
	else:
		shape = get_collision_shape(0.0)

	#Color selection
	var colorUsed: Color
	if is_skill_energy_affordable(skill_current) and not is_skill_cooling_down(skill_current):
		colorUsed = color_hitbox
	else:
		colorUsed = color_hitbox_unusable

	#Drawing
	if shape is CircleShape2D:
		draw_circle(localPoint, shape.radius, colorUsed*0.35)
		draw_arc(localPoint, shape.radius, 0, TAU, hitbox_circle_outline_point_count, colorUsed, hitbox_line_thickness, hitbox_line_antialiasing)
	
	elif shape is SegmentShape2D:
		var points: Array[Vector2] = [shape.a + localPoint, shape.b + localPoint]
		draw_line(points[0], points[1], colorUsed, hitbox_line_thickness, hitbox_line_antialiasing)
	
	elif shape is ConvexPolygonShape2D:
		assert(shape.points.size() >= 3)
		var polygon: PackedVector2Array = []

		#Shift polygon points towards the mouse's position
		for point in shape.points:
			polygon.append(point + localPoint)

		draw_colored_polygon(polygon, colorUsed)


func add_skill(skillClass: String):
	#Do not allow duplicates
	if skillClass in get_skills_classes():
		if Global.debug_mode:
			GodotLogger.info(
				"Rejected duplicate skill '{0}'".format([skillClass])
				)
		return
		
	var skillFound: SkillComponentResource = J.skill_resources.get(skillClass, null)

	if skillFound is SkillComponentResource:
		skills.append(skillFound.duplicate())
		skills_changed.emit()


func remove_skill(skillClass: String):
	for skill in skills:
		if skill.skill_class == skillClass:
			skills.erase(skill)
			skills_changed.emit()
			return


func skill_select_by_index(index: int):
	#The index can range from -1 to size()-1
	if not (index >= -1 and index < skills.size()):
		#A wrong value does nothing.
		return

	#If -1 OR it was already selected, treat it as a deselection attempt.
	#It is important to check if skill_current isn't null
	if index == -1 or (skill_current and get_skill_current_class() == skill_current.skill_class):
		skill_deselect()
		return

	#Otherwise, change the skill properly
	skill_current = skills[index]

	#This must be separate from the skill_current setter to avoid infinite loops
	if skill_current.cast_on_select:
		skill_cast_on_select_selected.emit(skill_current)


#Can only find skills inside this component, fails otherwise.
func skill_select_by_class(skillClass: String):
	for skill in skills:
		if skill.skill_class == skillClass:
			skill_current = skill

			#This must be separate from the skill_current setter to avoid infinite loops
			if skill_current.cast_on_select:
				skill_cast_on_select_selected.emit(skill_current)

			return

	GodotLogger.warn('Could not find "{0}" skill in this component'.format([skillClass]))


func skill_deselect():
	skill_current = null


func skill_use_at(globalPoint: Vector2, skillClass: String = get_skill_current_class()):
	var skillUsed: SkillComponentResource = J.skill_resources[skillClass].duplicate()
	skill_current = skillUsed

	#Prepare the usage info.
	var skillUsageInfo := UseInfo.new()
	skillUsageInfo.user = user
	skillUsageInfo.targets = get_targets(globalPoint)
	skillUsageInfo.position_target_global = globalPoint

	#Check the expected result of attempting this use.
	var skillUseResult: SKILL_ATTEMPT_RESULT = get_skill_use_expected_result(
		skillUsed, skillUsageInfo
	)

	#If usable
	if skillUseResult == SKILL_ATTEMPT_RESULT.OK:
		#Perform the usage IF it's the server
		if G.is_server():
			#Perform the skill's effect on the targets
			skillUsed.effect(skillUsageInfo)
			#Use up energy
			stats_component.energy_recovery(skillUsageInfo.user.get_name(), -skillUsed.energy_usage)

		#Emit success and start cooldown on both
		skill_successful_usage.emit(skillUsed)
		cooldown_set_time_left(skillUsed.skill_class, skillUsed.cooldown)
	else:
		skill_failed_usage.emit(skillUsed)

	#Broadcast the result regardless of success
	skill_attempt_result.emit(skillUseResult)

	#cast_on_select skills should never stay selected.
	if skillUsed.cast_on_select:
		skill_deselect()


func get_targets(globalPos: Vector2) -> Array[Node]:
	var shapeParameters := PhysicsShapeQueryParameters2D.new()

	shapeParameters.collide_with_areas = true
	shapeParameters.collide_with_bodies = false

	#If the hitbox should be rotated, do so.
	if skill_current.hitbox_rotate_shape:
		shapeParameters.shape = get_collision_shape(user.global_position.angle_to_point(globalPos))

	else:
		shapeParameters.shape = get_collision_shape(0.0)

	#Move to target location
	shapeParameters.transform = shapeParameters.transform.translated(globalPos)

	#Set the correct collisions
	shapeParameters.collision_mask = skill_current.collision_mask

	#Exclude the user if this skill is not meant to target them. (Candidate for removal, somewhat unnecessary)
	if not skill_current.hitbox_hits_user:
		shapeParameters.exclude = [user.get_rid()]

	#Get the current physics space to use
	directSpace = user.get_world_2d().direct_space_state

	#Get and store all targets found
	var collisions: Array[Dictionary] = directSpace.intersect_shape(shapeParameters)
	var targets: Array[Node] = []
	for coll in collisions:
		targets.append(coll.get("collider").get_parent())

	#Custom filter per skill, defaults to allow everything
	targets.filter(skill_current._target_filter)
	return targets


func get_collision_shape(userRotation: float) -> Shape2D:
	var shape: Shape2D
	#Do not allow shapes with a size of 2, as it would denote a line, which is not yet supported
	assert(skill_current.hitbox_shape.size() != 2)

	#If it is only 1 point, treat it as a circle
	if skill_current.hitbox_shape.size() == 1:
		shape = CircleShape2D.new()
		shape.radius = skill_current.hitbox_shape[0].length()

	#Otherwise, it is a line
	elif skill_current.hitbox_shape.size() == 2:
		shape = SegmentShape2D.new()
		shape.a = skill_current.hitbox_shape[0]
		shape.b = skill_current.hitbox_shape[1]

	#Otherwise treat it as a polygon
	else:
		shape = ConvexPolygonShape2D.new()
		var newPoints: PackedVector2Array = []
		for point in skill_current.hitbox_shape:
			newPoints.append(point.rotated(userRotation))

		shape.points = newPoints

		assert(shape.points.size() >= 3)

	return shape


func get_collision_layer() -> int:
	assert(skill_current.collision_mask != 0)
	return skill_current.collision_mask


func cooldown_get_time_left(skillClass: String) -> float:
	assert(skillClass != "")
	return cooldownDict.get(skillClass, 0 as float)


#Sets cooldowns for skills per class
func cooldown_set_time_left(skillClass: String, time: float):
	cooldownDict[skillClass] = time
	skill_cooldown_updated.emit(skillClass, time)


func get_skill_current_class() -> String:
	if skill_current is SkillComponentResource:
		return skill_current.skill_class
	else:
		return ""


func get_skills_classes() -> Array[String]:
	var arr: Array[String] = []
	for skill in skills:
		arr.append(skill.skill_class)
	return arr


func is_skill_present(skillClass: String) -> bool:
	for skill in skills:
		if skill.skill_class == skillClass:
			return true
	return false


func get_skill_use_expected_result(
	skill: SkillComponentResource, useInfo: UseInfo
) -> SKILL_ATTEMPT_RESULT:
	if is_skill_cooling_down(skill):
		return SKILL_ATTEMPT_RESULT.COOLDOWN_RUNNING

	if not is_skill_energy_affordable(skill):
		return SKILL_ATTEMPT_RESULT.INSUFFICIENT_ENERGY

	if not is_skill_target_within_range(
		skill, useInfo.user.global_position, useInfo.position_target_global
	):
		return SKILL_ATTEMPT_RESULT.OUT_OF_RANGE

	return SKILL_ATTEMPT_RESULT.OK


func is_skill_cooling_down(skill: SkillComponentResource) -> bool:
	return not is_zero_approx(cooldown_get_time_left(skill.skill_class))


func is_skill_energy_affordable(skill: SkillComponentResource) -> bool:
	return stats_component.energy >= skill.energy_usage


func is_skill_target_within_range(
	skill: SkillComponentResource, userPosGlobal: Vector2, targetPosGlobal: Vector2
):
	return userPosGlobal.distance_to(targetPosGlobal) <= skill.hit_range


func to_json() -> Dictionary:
	var output: Dictionary = {}
	var slotIdx: int = 0
	for skill in skills:
		output[slotIdx] = skill.skill_class
		slotIdx += 1
	return output


func from_json(data: Dictionary) -> bool:
	for slotIdx in data:
		if not data[slotIdx] is String:
			GodotLogger.warn(
				'Failed to load skills from data, missing "skill_class" for slot {0}'.format(
					[str(slotIdx)]
				)
			)
			return false

		skills[slotIdx] = J.skill_resources[data[slotIdx]].duplicate()
		assert(skills[slotIdx] is SkillComponentResource)
	return true


func sync_skills(id: int):
	assert(G.is_server(), "Only the server may call this function")
	G.sync_rpc.skillcomponent_sync_response.rpc_id(id, user.get_name(), to_json())


func sync_response(skillDict: Dictionary):
	from_json(skillDict)


class UseInfo:
	extends Object
	var user: Node
	var targets: Array[Node]
	var position_target_global: Vector2

	func get_targets_filter_entities() -> Array[Node]:
		return targets.filter(func(toFilter: Node): return toFilter.get("entity_type") != null)

	#This subclass has issues referencing J.ENTITY_TYPE, so it is casted as int
	func get_targets_filter_entity_type(entityType: int) -> Array[Node]:
		return get_targets_filter_entities().filter(
			func(toFilter: Node): return toFilter.get("entity_type") == entityType
		)

	func get_position_local_from_user() -> Vector2:
		return position_target_global - user.global_position

	func get_user_stats() -> StatsSynchronizerComponent:
		var stats = user.get("stats")
		if stats is StatsSynchronizerComponent:
			return stats
		else:
			return null

	func get_target_stats_by_index(index: int) -> StatsSynchronizerComponent:
		if abs(index) >= abs(targets.size()):
			GodotLogger.error("SkillComponent.UseInfo, index out of range.")
			return null

		var stats: StatsSynchronizerComponent = targets[index]
		if stats is StatsSynchronizerComponent:
			return stats
		else:
			GodotLogger.error('Target lacks a "stats" property: ' + targets[index].get_name())
			return null

	func get_target_stats_all() -> Array[StatsSynchronizerComponent]:
		var statArr: Array[StatsSynchronizerComponent] = []
		for target in targets:
			var stats: StatsSynchronizerComponent = target.get("stats")
			if stats is StatsSynchronizerComponent:
				statArr.append(stats)
			else:
				GodotLogger.error('Target lacks a "stats" property: ' + target.get_name())
		return statArr

	func get_target_names() -> Array[String]:
		var names: Array[String] = []
		for entity in get_targets_filter_entities():
			names.append(entity.get_name())
		return names

	func to_json(usageInfo: UseInfo) -> Dictionary:
		return {
			"user": usageInfo.user.get_name(),
			"targets": usageInfo.get_target_names(),
			"position_global": usageInfo.position_target_global
		}

	func from_json(data: Dictionary) -> bool:
		if not "user" in data:
			GodotLogger.warn('Failed to load equipment from data, missing "user" key')
			return false

		if not "targets" in data:
			GodotLogger.warn('Failed to load equipment from data, missing "targets" key')
			return false

		if not "position_global" in data:
			GodotLogger.warn('Failed to load equipment from data, missing "position_global" key')
			return false

		assert(data["user"] is String)
		assert(data["targets"] is Array[String])
		assert(data["position_global"] is Vector2)

		var foundUser: Node
		if J.world.players.has_node(data["user"]):
			foundUser = J.world.players.get_node(data["user"])
		elif J.world.enemies.has_node(data["user"]):
			foundUser = J.world.enemies.get_node(data["user"])
		elif J.world.npcs.has_node(data["user"]):
			foundUser = J.world.npcs.get_node(data["user"])

		var foundTargets: Array[Node] = []
		for possibleTarget in data["targets"]:
			if J.world.players.has_node(data["user"]):
				foundTargets.append(J.world.players.get_node(data["user"]))
			elif J.world.enemies.has_node(data["user"]):
				foundTargets.append(J.world.enemies.get_node(data["user"]))
			elif J.world.npcs.has_node(data["user"]):
				foundTargets.append(J.world.npcs.get_node(data["user"]))

		user = foundUser
		targets = foundTargets
		position_target_global = data["position_global"]
		return true


func print_skill_attempt_result(result: SKILL_ATTEMPT_RESULT):
	if Global.debug_mode:
		print(
			(
				"'"
				+ user.get_name()
				+ "' attempted to use skill '"
				+ skill_current.skill_class
				+ "' with result: '"
				+ SKILL_ATTEMPT_RESULT.find_key(result)
				+ "' on instance "
				+ get_window().title
			)
		)


func _on_skill_used(where: Vector2, skillClass: String):
	skill_use_at(where, skillClass)
