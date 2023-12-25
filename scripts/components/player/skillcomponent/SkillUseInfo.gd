extends Object

class_name SkillUseInfo

var user: Node
var targets: Array[Node]
var position_target_global: Vector2


func get_targets_filter_entities() -> Array[Node]:
	return targets.filter(func(to_filter: Node): return to_filter.get("entity_type") != null)


#This subclass has issues referencing J.ENTITY_TYPE, so it is casted as int
func get_targets_filter_entity_type(entity_type: int) -> Array[Node]:
	return get_targets_filter_entities().filter(
		func(to_filter: Node): return to_filter.get("entity_type") == entity_type
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
	var stat_arr: Array[StatsSynchronizerComponent] = []
	for target in targets:
		var stats: StatsSynchronizerComponent = target.get("stats")
		if stats is StatsSynchronizerComponent:
			stat_arr.append(stats)
		else:
			GodotLogger.error('Target lacks a "stats" property: ' + target.get_name())
	return stat_arr


func get_target_names() -> Array[String]:
	var names: Array[String] = []
	for entity in get_targets_filter_entities():
		names.append(entity.get_name())
	return names


func to_json(usage_info: SkillUseInfo) -> Dictionary:
	return {
		"user": usage_info.user.get_name(),
		"targets": usage_info.get_target_names(),
		"position_global": usage_info.position_target_global
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

	var found_user: Node
	if J.world.players.has_node(data["user"]):
		found_user = J.world.players.get_node(data["user"])
	elif J.world.enemies.has_node(data["user"]):
		found_user = J.world.enemies.get_node(data["user"])
	elif J.world.npcs.has_node(data["user"]):
		found_user = J.world.npcs.get_node(data["user"])

	var found_targets: Array[Node] = []
	for possibleTarget in data["targets"]:
		if J.world.players.has_node(data["user"]):
			found_targets.append(J.world.players.get_node(data["user"]))
		elif J.world.enemies.has_node(data["user"]):
			found_targets.append(J.world.enemies.get_node(data["user"]))
		elif J.world.npcs.has_node(data["user"]):
			found_targets.append(J.world.npcs.get_node(data["user"]))

	user = found_user
	targets = found_targets
	position_target_global = data["position_global"]
	return true

static func get_entity_component(entity: Node, component_name: String) -> Node:
	if entity.get("component_list") is Dictionary:
		var comp: Node = entity.component_list.get(component_name, null)
		if comp == null:
			GodotLogger.error("The user '{0}' lacks a '{1}' component".format([entity.get_name(), component_name]))
		return comp
	else:
		GodotLogger.error("The user '{0}' does not have a component_list property, it may not be an entity.".format([entity.get_name()]))
		return null
