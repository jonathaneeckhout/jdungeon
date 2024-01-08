extends Node
class_name ProjectileSynchronizerComponent

signal projectile_launched(target: Vector2, projectile_class: String)

signal projectile_hit_object(object: Node2D)
signal projectile_hit_entity(entity: Node2D)

const COMPONENT_NAME: String = "projectile_synchronizer"

## Should anything projectile related survive for this long, delete it.
const MAX_PROJECTILE_LIFESPAN: float = 300.0
const MAX_COLLISION_LIFESPAN: float = 10.0

@export var watcher_component: WatcherSynchronizerComponent

var target_node: Node

## Server only
## This keeps a list of instances of projectiles of a specific class, from a specific entity. used to limit the amount of projectiles per entity.
var instance_tracker: Dictionary

func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list[COMPONENT_NAME] = self

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return


func launch_projectile(target_global_pos: Vector2, projectile_class: String):
	var projectile: Projectile2D = create_projectile_node(projectile_class)

	# Do not hit owner
	projectile.add_collision_exception_with(target_node)

	if projectile.ignore_terrain:
		projectile.remove_collision_mask(J.PHYSICS_LAYER_WORLD)
		
	if projectile.collide_with_other_projectiles:
		projectile.add_collision_mask(J.PHYSICS_LAYER_PROJECTILE)

	if projectile.ignore_same_entity_type:
		match target_node.entity_type:
			J.ENTITY_TYPE.PLAYER:
				projectile.remove_collision_mask(J.PHYSICS_LAYER_PLAYERS)
			J.ENTITY_TYPE.NPC:
				projectile.remove_collision_mask(J.PHYSICS_LAYER_NPCS)
			J.ENTITY_TYPE.ENEMY:
				projectile.remove_collision_mask(J.PHYSICS_LAYER_ENEMIES)
			_:
				GodotLogger.warn("Cannot determine the type of entity that fired this projectile.")

	# Set position and add to tree
	G.world.add_child(projectile)
	projectile.global_position = target_node.global_position
	
	projectile.launch(target_global_pos)
	

	# Delete the projectile if it lives for longer than its lifespan or the maximum allowed lifespawn.
	var projectile_timer: SceneTreeTimer = get_tree().create_timer(min(MAX_PROJECTILE_LIFESPAN, projectile.lifespan))
	projectile_timer.timeout.connect(projectile.queue_free)

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
		
		#Also remove the tracking once this is over
		projectile_timer.timeout.connect(remove_track_instance.bind(target_node.get_name(), target_node.get("entity_type"), projectile))
		
		add_track_instance(target_node.get_name(), target_node.get("entity_type"), projectile)
		
		
		for entity: Node in watcher_component.watchers + [target_node]:
			var target_id: int = entity.get("peer_id")
			if target_id is int:
				sync_launch_to_client(
					target_node.peer_id, target_global_pos, projectile_class
				)
				if Global.debug_mode:
					GodotLogger.info("Synched projectile '{0}' with peer '{1}'".format([projectile_class, str(target_node.peer_id)]))


func sync_launch_to_client(
	id: int, target_global_pos: Vector2, projectile_class: String
):
	var json_data: Dictionary = launch_to_json(target_global_pos, projectile_class)
	G.sync_rpc.projectilesynchronizer_sync_launch.rpc_id(id, target_node.get_name(), json_data)


func sync_launch_to_client_response(json_data: Dictionary):
	launch_from_json(json_data)


func launch_to_json(
	target_global_pos: Vector2, projectile_class: String
) -> Dictionary:
	var output: Dictionary = {}

	output["target_global_pos"] = target_global_pos
	output["projectile_class"] = projectile_class

	return output


func add_track_instance(entity: String, type: J.ENTITY_TYPE, projectile_node: Projectile2D):
	assert(G.is_server())
	var max_instances: int = projectile_node.instance_limit
	if not instance_tracker.has(entity+str(type)):
		instance_tracker[entity+str(type)] = []
	
	var oldest_projectile: Projectile2D = instance_tracker[entity+str(type)].front()
	# If the limit was exceeded and the oldest entity is not currently being deleted, do so.
	if get_track_instance_count(entity, type, projectile_node) > projectile_node.instance_limit:
		remove_track_instance(entity, type, oldest_projectile)
		
	if is_instance_valid(oldest_projectile):
		oldest_projectile.queue_free()
		
		
	instance_tracker[entity+str(type)+projectile_node.projectile_class].append(projectile_node)
	

func get_track_instance_count(entity: String, type: J.ENTITY_TYPE, projectile_node: Projectile2D) -> int:
	assert(G.is_server())
	if instance_tracker.get(entity+str(type)+projectile_node.projectile_class, []).is_empty():
		GodotLogger.warn("There are no projectiles with key '{0}' being tracked by this component.".format([entity+str(type)+projectile_node.projectile_class]))
		
	var count: int = instance_tracker.get(entity+str(type)+projectile_node.projectile_class, []).size()
	return count


func remove_track_instance(entity: String, type: J.ENTITY_TYPE, projectile_node: Projectile2D):
	assert(G.is_server())
	instance_tracker.get(entity+str(type)+projectile_node.projectile_class, []).erase(projectile_node)


func launch_from_json(data: Dictionary):
	for key: String in ["target_global_pos", "projectile_class", "misc"]:
		if not key in data:
			GodotLogger.error("Missing '{0}' key for this projectile sync")

	launch_projectile(data["target_global_pos"], data["projectile_class"])


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
