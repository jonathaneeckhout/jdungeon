extends Node
class_name SkillComponent
## Takes care of handling skills, their effects, cooldowns and costs, as well as the drawing of hitboxes for player feedback.

#TODO:
#Connect player input to skill usage
#Prepare an UI element to check skills 

signal skill_successful_usage(skill: SkillComponentResource)
signal skill_failed_usage(skill: SkillComponentResource)
signal skill_selected(skill: SkillComponentResource)
signal skill_index_selected(index: int)

const COLOR_HITBOX := Color.AQUA / 2
const COLOR_HITBOX_UNUSABLE := Color.FIREBRICK / 2
const COLOR_RANGE := Color.GREEN_YELLOW / 2


@export var user: CharacterBody2D:
	set(val):
		user = val
		var lateConnection: Callable = func():
			directSpace = user.get_world_2d().direct_space_state
			user.draw.connect(draw_on_user)
		if user.is_inside_tree():
			lateConnection.call()
		else:
			user.tree_entered.connect(lateConnection)
		
		
@export var stats_component: StatsSynchronizerComponent
@export var player_synchronizer: PlayerSynchronizer

@export var skills: Array[SkillComponentResource]
@export var skill_current: SkillComponentResource:
	set(val):
		#Stop here if it is a null value
		if val is SkillComponentResource:
			skill_current = val.duplicate()
		else: 
			skill_current = null
			return
		
		#Throw an error if this skill is not from this SkillComponent
		if not skill_current in skills:
			J.logger.error('The skill of class {0} does not belong to this component'.format([skill_current.skill_class]))
			return
		
		var skillIndex: int = skills.find(skill_current)
		assert(skillIndex != -1, "Could not find this skill despite being in the array!")
		
		skill_index_selected.emit(skillIndex)
		skill_selected.emit(skill_current)


var cooldownDict: Dictionary
var directSpace: PhysicsDirectSpaceState2D
var shapeParameters := PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	#TEMP
	skills.append( J.skill_resources["debug"].duplicate() )
	skill_current = skills[0]
	assert(skills[0].skill_class == "debug")
	assert(not skills.is_empty())
	#TEMP
	
	if J.is_server():
		return
	
	#Wait until the connection is ready to synchronize stats
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server
		
	#Wait an additional frame so others can get set.
	await get_tree().process_frame
	
	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered
	
	sync_skills.rpc_id(1)

#TEMP
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("j_slot1"):
		skill_select_by_index(0)
	elif event.is_action_pressed("j_slot2"):
		skill_select_by_index(1)
	elif event.is_action_pressed("j_slot3"):
		skill_select_by_index(2)
	elif event.is_action_pressed("j_slot4"):
		skill_select_by_index(3)
	elif event.is_action_pressed("j_slot5"):
		skill_select_by_index(4)
#TEMP


func draw_on_user():
	if not skill_current is SkillComponentResource:
		return
		
	elif skill_current.hitbox_shape.size() <= 0:
		return
		
	print_debug(skill_current)
	print_debug(skill_current.hitbox_shape)
	
	draw_range()
	draw_hitbox()
	
func draw_range():
	user.draw_circle(Vector2.ZERO, skill_current.hit_range, COLOR_RANGE)
	
func draw_hitbox(localPoint: Vector2 = player_synchronizer.mouse_global_pos - user.global_position):
	var shape: Shape2D
	if skill_current.hitbox_rotate_shape:
		shape = get_collision_shape(user.global_position.angle_to_point(localPoint))
	else:
		shape = get_collision_shape(0.0)
		
	var colorUsed: Color
	
	#Color selection
	if is_skill_usable(skill_current):
		colorUsed = COLOR_HITBOX
	else:
		colorUsed = COLOR_HITBOX_UNUSABLE
	
	#Drawing
	if shape is CircleShape2D:
		user.draw_circle(localPoint, shape.radius, colorUsed)
		
	elif shape is ConvexPolygonShape2D:
		assert(shape.points.size() >= 3)
		var polygon: PackedVector2Array = []
		for point in shape.points:
			polygon.append(point + localPoint)
			
		user.draw_colored_polygon(polygon, colorUsed)

func skill_select_by_index(index: int):
	#Array supports negative values to select from the end of the Array
	if not abs(index) < abs(skills.size()):
		J.logger.error("Slot index out of range.") #TEMP
		return
		
	skill_current = skills[index]
	
	print_debug("Selected skill " + skill_current.displayed_name + " of class " + skill_current.skill_class)

func skill_deselect():
	skill_current = null

func skill_use_at(globalPoint: Vector2, skillClass: String = get_skill_current_class()):
	
	skill_current = J.skill_resources[skillClass].duplicate()
	
	if not is_skill_usable(skill_current):
		skill_failed_usage.emit(skill_current)
		return
	
	if user.global_position.distance_to(globalPoint) > skill_current.hit_range:
		skill_failed_usage.emit(skill_current)
		return
	
	var skillUsageInfo := UseInfo.new()
	skillUsageInfo.user = user
	skillUsageInfo.targets = get_targets(globalPoint)
	skillUsageInfo.position_target_global = globalPoint
	
	handle_cooldown(skill_current, true)
	
	skill_current.effect(skillUsageInfo)
	skill_successful_usage.emit(skill_current)
	
	
func get_targets(where: Vector2)->Array[Node]:
	if skill_current.hitbox_rotate_shape:
		shapeParameters.shape = get_collision_shape(user.global_position.angle_to_point(where))
	else:
		shapeParameters.shape = get_collision_shape(0.0)
	shapeParameters.collision_mask = get_collision_layer()
	
	if not skill_current.hitbox_hits_user:
		shapeParameters.exclude = [user.get_rid()]
		
	
		
		pass
	
	var collisions: Array[Dictionary] = directSpace.intersect_shape(shapeParameters)
	var targets: Array[Node] = []
	for coll in collisions:
		targets.append(coll.get("collider"))
		
	targets.filter(skill_current._target_filter)
	return targets
	
func get_collision_shape(userRotation: float)->Shape2D:
	var shape: Shape2D
	#Do not allow shapes with a size of 2
	assert(skill_current.hitbox_shape.size() != 2)
	
	#If it is only 1 point, treat it as a circle
	if skill_current.hitbox_shape.size() == 1:
		shape = CircleShape2D.new()
		shape.radius = skill_current.hitbox_shape[0]
		assert( shape.points.size() == 1 )
		
	#Otherwise treat it as a polygon
	else:
		shape = ConvexPolygonShape2D.new()
		var newPoints: PackedVector2Array
		for point in skill_current.hitbox_shape:
			newPoints.append(point.rotated(userRotation))
		shape.points = newPoints
		
		assert( shape.points.size() >= 3 )
	
	return shape

func get_collision_layer()->int:
	return skill_current.collision_mask

func handle_cooldown(skill: SkillComponentResource, started: bool):
	#Start the cooldown and set the skill as "cooling down"
	if started:
		cooldownDict[skill] = true
		get_tree().create_timer(skill.cooldown).timeout.connect(handle_cooldown.bind(false))
	#Remove the skill from the "cooling down" list
	else:
		cooldownDict.erase(skill)
	
func get_skill_current_class()->String:
	if skill_current is SkillComponentResource:
		return skill_current.skill_class
	else: 
		return ""
	
func is_skill_usable(skill: SkillComponentResource)->bool:
	if not stats_component.energy >= skill.energy_usage:
		return false
	
	if cooldownDict.has(skill):
		return false
		
	return true
	
func to_json()->Dictionary:
	var output: Dictionary = {}
	var slotIdx: int = 0
	for skill in skills:
		output[slotIdx] = skill.skill_class
		slotIdx += 1
	return output

func from_json(data: Dictionary)->bool:
	for slotIdx in data:
		
		if not data[slotIdx] is String:
			J.logger.warn('Failed to load skills from data, missing "skill_class" for slot {0}'.format([str(slotIdx)]))
			return false
			
		skills[slotIdx] = J.skill_resources[data[slotIdx]].duplicate()
	return true


@rpc("call_remote", "any_peer", "reliable") func sync_skills():
	if not J.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	sync_response.rpc_id(id, to_json())
	
@rpc("call_remote", "authority", "reliable") func sync_response(skillDict: Dictionary):
	from_json(skillDict)

class UseInfo extends Object:
	var user: Node
	var targets: Array[Node]
	var position_target_global: Vector2
		
	func get_targets_filter_entities()->Array[Node]:
		return targets.filter(
			func(toFilter:Node):
			return toFilter.get("entity_type") != null
			)
	
	#This subclass has issues referencing J.ENTITY_TYPE, so it is casted as int
	func get_targets_filter_entity_type(entityType: int)->Array[Node]:
			return get_targets_filter_entities().filter(
				func(toFilter:Node):
				return toFilter.get("entity_type") == entityType
			)
		
		
	func get_position_local_from_user()->Vector2:
		return position_target_global - user.global_position

	func get_user_stats()->StatsSynchronizerComponent:
		var stats = user.get("stats")
		if stats is StatsSynchronizerComponent:
			return stats
		else:
			return null
	
	func get_target_stats_by_index(index: int)->StatsSynchronizerComponent:
		if abs(index) >= abs(targets.size()):
			J.logger.error("SkillComponent.UseInfo, index out of range.")
			return null
		
		var stats: StatsSynchronizerComponent = targets[index]
		if stats is StatsSynchronizerComponent:
			return stats
		else:
			J.logger.error('Target lacks a "stats" property: ' + targets[index].get_name())
			return null

	func get_target_stats_all()->Array[StatsSynchronizerComponent]:
		var statArr: Array[StatsSynchronizerComponent] = []
		for target in targets:
			var stats: StatsSynchronizerComponent = target.get("stats")
			if stats is StatsSynchronizerComponent:
				statArr.append(stats)
			else:
				J.logger.error('Target lacks a "stats" property: ' + target.get_name())
		return statArr

	func get_target_names()->Array[String]:
		var names: Array[String] = []
		for entity in get_targets_filter_entities():
			names.append(entity.get_name())
		return names
		
	func to_json(usageInfo: UseInfo)->Dictionary:
		return {"user": usageInfo.user.get_name(), "targets":usageInfo.get_target_names(), "position_global":usageInfo.position_target_global}

	func from_json(data: Dictionary)->bool:
		if not "user" in data:
			J.logger.warn('Failed to load equipment from data, missing "user" key')
			return false
			
		if not "targets" in data:
			J.logger.warn('Failed to load equipment from data, missing "targets" key')
			return false
			
		if not "position_global" in data:
			J.logger.warn('Failed to load equipment from data, missing "position_global" key')
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
			
