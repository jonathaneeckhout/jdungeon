extends Node
class_name SkillComponent

signal skill_successful_usage(skill: SkillComponentResource)
signal skill_failed_usage(skill: SkillComponentResource)
signal skill_selected(skill: SkillComponentResource)

const COLOR_HITBOX := Color.AQUA / 2
const COLOR_HITBOX_UNUSABLE := Color.FIREBRICK / 2
const COLOR_RANGE := Color.GREEN_YELLOW / 2


@export var user: CharacterBody2D:
	set(val):
		user = val
		directSpace = user.get_world_2d().direct_space_state
		user.draw.connect(draw_on_user)
		
@export var stats_component: StatsSynchronizerComponent
@export var input_component: InputSynchronizerComponent

@export var skills: Array[SkillComponentResource]
@export var skill_current: SkillComponentResource:
	set(val):
		skill_current = val
		skill_selected.emit(skill_current)


var cooldownDict: Dictionary
var directSpace: PhysicsDirectSpaceState2D
var shapeParameters := PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	#Wait until the connection is ready to synchronize stats
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server
		
	#Wait an additional frame so others can get set.
	await get_tree().process_frame
	
	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered
	
	sync_skills.rpc_id(1)


func draw_on_user():
	if not skill_current:
		return
	draw_range()
	draw_hitbox()
func draw_range():
	user.draw_circle(Vector2.ZERO, skill_current.hit_range, COLOR_RANGE)
func draw_hitbox(atPoint: Vector2 = input_component.cursor_position_global):

	var shape: Shape2D = get_collision_shape()
	var colorUsed: Color
	
	#Color selection
	if is_skill_usable(skill_current):
		colorUsed = COLOR_HITBOX
	else:
		colorUsed = COLOR_HITBOX_UNUSABLE
	
	#Drawing
	if shape is CircleShape2D:
		user.draw_circle(atPoint, shape.radius, colorUsed)
		
	elif shape is ConvexPolygonShape2D:
		var polygon: PackedVector2Array
		for point in shape.points:
			polygon.append(point + atPoint)
			
		user.draw_colored_polygon(polygon, colorUsed)

func skill_select_by_index(index: int):
	#Array supports negative values to select from the end of the Array
	if not abs(index) < abs(skills.size()):
		J.logger.error("Slot index out of range.") #TEMP
		return
		
	skill_current = skills[index]

func skill_deselect():
	skill_current = null

func use_at(globalPoint: Vector2):
	if not is_skill_usable(skill_current):
		skill_failed_usage.emit(skill_current)
		return
	
	if user.global_position.distance_to(globalPoint) > skill_current.hit_range:
		skill_failed_usage.emit(skill_current)
		return
	
	var targets: Array[Node] = get_targets(globalPoint)
	handle_cooldown(skill_current, true)
	skill_current.effect(targets)
	skill_successful_usage.emit(skill_current)
	
	
func get_targets(where: Vector2)->Array[Node]:
	shapeParameters.shape = get_collision_shape()
	
	var collisions: Array[Dictionary] = directSpace.intersect_shape(shapeParameters)
	var targets: Array[Node] = []
	for coll in collisions:
		targets.append(coll.get("collider"))
		
	targets.filter(skill_current._target_filter)
	return targets
	
func get_collision_shape()->Shape2D:
	var shape: Shape2D
	#Do not allow shapes with a size of 2
	assert(skill_current.hitbox_shape.size() != 2)
	
	#If it is only 1 point, treat it as a circle
	if skill_current.hitbox_shape.size() == 1:
		shape = CircleShape2D.new()
		shape.radius = skill_current.hitbox_shape[0]
		
	#Otherwise treat it as a polygon
	else:
		shape = ConvexPolygonShape2D.new()
		shape.points = skill_current.hitbox_shape
		
	return shape

func handle_cooldown(skill: SkillComponentResource, started: bool):
	#Start the cooldown and set the skill as "cooling down"
	if started:
		cooldownDict[skill] = true
		get_tree().create_timer(skill.cooldown).timeout.connect(handle_cooldown.bind(false))
	#Remove the skill from the "cooling down" list
	else:
		cooldownDict.erase(skill)
	
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
	
func sync_response(skills: Dictionary):
	from_json(skills)
