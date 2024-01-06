extends Node
class_name ProjectileSynchronizerComponent

signal projectile_launched(target: Vector2, projectile_class: String)

signal projectile_hit_object(object: Node2D)
signal projectile_hit_entity(entity: Node2D)

const COMPONENT_NAME: String = "projectile_synchronizer"

## Should anything projectile related survive for this long, delete it.
const MAX_PROJECTILE_LIFESPAN: float = 40.0
const MAX_COLLISION_LIFESPAN: float = 10.0

@export var watcher_component: WatcherSynchronizerComponent
@export var skill_component: SkillComponent

var target_node: Node


func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list[COMPONENT_NAME] = self

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return


func launch_projectile(target_global_pos: Vector2, projectile_class: String, misc: Dictionary):
	var projectile: Projectile2D = create_projectile_node(projectile_class)

	if not projectile.is_misc_data_valid(misc):
		GodotLogger.error(
			"The 'misc' data passed to this projectile does not match the expected keys."
		)
		projectile.queue_free()
		return

	# Do not hit owner
	projectile.add_collision_exception_with(target_node)

	if projectile.ignore_terrain:
		projectile.remove_collision_mask_bit(J.PHYSICS_LAYER_WORLD)

	if projectile.ignore_same_entity_type:
		match target_node.entity_type:
			J.ENTITY_TYPE.PLAYER:
				projectile.remove_collision_mask_bit(J.PHYSICS_LAYER_PLAYERS)
			J.ENTITY_TYPE.NPC:
				projectile.remove_collision_mask_bit(J.PHYSICS_LAYER_NPCS)
			J.ENTITY_TYPE.ENEMY:
				projectile.remove_collision_mask_bit(J.PHYSICS_LAYER_ENEMIES)
			_:
				GodotLogger.warn("Cannot determine the type of entity that fired this projectile.")

	# Set position and add to tree
	projectile.global_position = target_node.global_position
	G.world.add_child(projectile)

	for key: String in projectile.misc:
		projectile.set_misc_data(key, misc[key])

	projectile.launch(target_global_pos)

	# Delete the projectile if it lives for longer than the allowed maximum lifespan. Ignoring it's own lifespan.
	get_tree().create_timer(MAX_PROJECTILE_LIFESPAN).timeout.connect(projectile.queue_free)

	if Global.debug_mode:
		GodotLogger.info(
			"Entity '{0}' fired projectile of class '{1}' from position {2} towards {3}".format(
				[
					target_node.get_name(),
					projectile_class,
					str(target_node.global_position),
					str(target_global_pos)
				]
			)
		)

	# If the server is launching the projectile, sync it.
	if G.is_server():
		projectile.hit_object.connect(_on_projectile_hit_object.bind(projectile))

		for entity: Node in watcher_component.watchers:
			var target_id: int = entity.get("peer_id")
			if target_id is int:
				sync_launch_to_client(
					target_node.peer_id, target_global_pos, projectile_class, misc
				)


func sync_launch_to_client(
	id: int, target_global_pos: Vector2, projectile_class: String, misc: Dictionary
):
	var json_data: Dictionary = launch_to_json(target_global_pos, projectile_class, misc)
	G.sync_rpc.projectilesynchronizer_sync_launch.rpc_id(id, json_data)


func sync_launch_to_client_response(json_data: Dictionary):
	launch_from_json(json_data)


func launch_to_json(
	target_global_pos: Vector2, projectile_class: String, misc: Dictionary
) -> Dictionary:
	var output: Dictionary

	output["target_global_pos"] = target_global_pos
	output["projectile_class"] = projectile_class
	output["misc"] = misc

	return output


func launch_from_json(data: Dictionary):
	for key: String in ["target_global_pos", "projectile_class", "misc"]:
		if not key in data:
			GodotLogger.error("Missing '{0}' key for this projectile sync")

	launch_projectile(data["target_global_pos"], data["projectile_class"], data["misc"])


func create_projectile_node(projectile_class: String) -> Projectile2D:
	return J.projectile_scenes[projectile_class].duplicate().instantiate()


func _on_projectile_hit_object(object: Node2D, projectile: Projectile2D):
	# Try to get an entity with the object's name, as to confirm it is one.
	var hit_entity: Node2D = G.world.get_entity_by_name(object.get_name())

	if hit_entity == null:
		projectile_hit_object.emit(object)
		return

	# If the projectile has a skill defined, use it.
	# This triggers [method SkillComponentResource.effect] directly and does not use hitboxes nor collision_masks.
	if projectile.skill_class != Projectile2D.NO_SKILL:
		var skill_used: SkillComponentResource = J.skill_resources[projectile.skill_class]
		var skill_usage_info := SkillUseInfo.new()

		skill_used.set_all_entities_as_valid()

		skill_usage_info.user = target_node
		skill_usage_info.targets = [hit_entity]
		skill_usage_info.position_target_global = hit_entity.global_position

		skill_used.effect(skill_usage_info)

	if projectile.collision_scene:
		var coll_scene_instance: Node2D = projectile.collision_scene.duplicate().instantiate()
		projectile.add_sibling(coll_scene_instance)
		coll_scene_instance.global_position = projectile.global_position

		# Ensure it doesn't linger for TOO long.
		get_tree().create_timer(MAX_COLLISION_LIFESPAN).timeout.connect(
			coll_scene_instance.queue_free
		)

	projectile_hit_object.emit(object)
	projectile_hit_entity.emit(hit_entity)
