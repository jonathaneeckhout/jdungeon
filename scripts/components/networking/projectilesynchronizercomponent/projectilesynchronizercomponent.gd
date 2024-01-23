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

	# Handle instance limit
	var projectile_group_name: String = get_projectile_group(
		target_node.get_name(), target_node.get("entity_type"), projectile_class
	)
	var projectiles_in_group: Array[Node] = get_tree().get_nodes_in_group(projectile_group_name)
	if projectiles_in_group.size() >= projectile.instance_limit:
		var projectile_arr: Array[Projectile2D] = []
		projectile_arr.assign(projectiles_in_group)
		var oldest_projectile: Projectile2D = get_oldest_projectile(projectile_arr)

		if is_instance_valid(oldest_projectile):
			oldest_projectile.remove_from_group(projectile_group_name)
			oldest_projectile.queue_free()

	projectile.add_to_group(projectile_group_name)

	# Do not hit owner
	projectile.add_collision_exception_with(target_node)

	if projectile.ignore_terrain:
		projectile.remove_collision_mask(J.PHYSICS_LAYER_WORLD)
	else:
		projectile.add_collision_mask(J.PHYSICS_LAYER_WORLD)

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
	var projectile_timer: SceneTreeTimer = get_tree().create_timer(
		min(MAX_PROJECTILE_LIFESPAN, projectile.lifespan)
	)
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

		for client_id: int in get_clients_in_range():
			sync_launch_to_client(client_id, target_global_pos, projectile_class)

			if Global.debug_mode:
				GodotLogger.info(
					"Synched projectile '{0}' with peer '{1}'".format(
						[projectile_class, str(target_node.peer_id)]
					)
				)


func sync_launch_to_client(id: int, target_global_pos: Vector2, projectile_class: String):
	var json_data: Dictionary = launch_to_json(target_global_pos, projectile_class)
	G.sync_rpc.projectilesynchronizer_sync_launch.rpc_id(id, target_node.get_name(), json_data)


func sync_launch_to_client_response(json_data: Dictionary):
	launch_from_json(json_data)


func launch_to_json(target_global_pos: Vector2, projectile_class: String) -> Dictionary:
	var output: Dictionary = {}

	output["target_global_pos"] = target_global_pos
	output["projectile_class"] = projectile_class

	return output


func launch_from_json(data: Dictionary):
	for key: String in ["target_global_pos", "projectile_class"]:
		if not key in data:
			GodotLogger.error("Missing '{0}' key for this projectile sync".format([key]))

	launch_projectile(data["target_global_pos"], data["projectile_class"])


func sync_collision_to_client(id: int, target_global_pos: Vector2, projectile_class: String):
	var json_data: Dictionary = collision_to_json(target_global_pos, projectile_class)
	G.sync_rpc.projectilesynchronizer_sync_collision.rpc_id(id, target_node.get_name(), json_data)


func sync_collision_to_client_response(json_data: Dictionary):
	collision_from_json(json_data)


func collision_to_json(target_global_pos: Vector2, projectile_class: String) -> Dictionary:
	var output: Dictionary = {}

	output["target_global_pos"] = target_global_pos
	output["projectile_class"] = projectile_class

	return output


func collision_from_json(data: Dictionary):
	for key: String in ["target_global_pos", "projectile_class"]:
		if not key in data:
			GodotLogger.error("Missing '{0}' key for this projectile sync".format([key]))

	show_collision(data["target_global_pos"], data["projectile_class"])


func create_projectile_node(projectile_class: String) -> Projectile2D:
	return J.projectile_scenes[projectile_class].duplicate().instantiate()


func show_collision(global_pos: Vector2, projectile_class: String):
	assert(not G.is_server())
	var projectile_scene: Projectile2D = (
		J.projectile_scenes[projectile_class].duplicate().instantiate()
	)

	if not projectile_scene.collision_scene is PackedScene:
		return

	var projectile_coll_scene_instance: Node = (
		projectile_scene.collision_scene.duplicate().instantiate()
	)
	G.world.add_child(projectile_coll_scene_instance)
	projectile_coll_scene_instance.global_position = global_pos

	if (
		projectile_coll_scene_instance is CPUParticles2D
		or projectile_coll_scene_instance is GPUParticles2D
	):
		projectile_coll_scene_instance.emitting = true
	elif Global.debug_mode:
		(
			GodotLogger
			. warn(
				"This scene does not contain a CPUParticles2D nor a GPUParticles2D node, its activation cannot be controlled from here."
			)
		)

	# Ensure it doesn't linger for TOO long.
	get_tree().create_timer(MAX_COLLISION_LIFESPAN).timeout.connect(
		projectile_coll_scene_instance.queue_free
	)


func _on_projectile_hit_object(object: Node2D, projectile: Projectile2D):
	var obj_hit: Node2D = object

	#If it touched a HurtBox, get the entity that owns it.
	if obj_hit.get_name() == "HurtArea" and get_parent():
		obj_hit = obj_hit.get_parent()

	var hit_entity: Node2D = null

	# Try to get an entity with the object's name if it is a CharacterBody2D, as to confirm it is one.
	if obj_hit is CharacterBody2D:
		hit_entity = G.world.get_entity_by_name(obj_hit.get_name())

	#If no entity was found, just report the object hit
	if hit_entity == null:
		projectile_hit_object.emit(obj_hit)
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

	for client_id: int in get_clients_in_range():
		sync_collision_to_client(client_id, projectile.position, projectile.projectile_class)

	projectile_hit_object.emit(obj_hit)
	projectile_hit_entity.emit(hit_entity)


func get_clients_in_range() -> Array[int]:
	var target_ids: Array[int] = []
	for entity: Node in watcher_component.watchers + [target_node]:
		var target_id: int = entity.get("peer_id")
		if target_id is int:
			target_ids.append(target_id)

	return target_ids


func get_projectile_group(entity: String, type: J.ENTITY_TYPE, projectile_class: String) -> String:
	return Projectile2D.NODE_GROUP_BASE + entity + str(type) + projectile_class


func get_projectile_count(group: String) -> int:
	return get_tree().get_nodes_in_group(group).size()


func get_oldest_projectile(projectiles: Array[Projectile2D]) -> Projectile2D:
	if projectiles.is_empty():
		return null

	var oldest_projectile: Projectile2D = projectiles.back()
	for projectile: Projectile2D in projectiles:
		if projectile.creation_time < oldest_projectile.creation_time:
			oldest_projectile = projectile

	return oldest_projectile
