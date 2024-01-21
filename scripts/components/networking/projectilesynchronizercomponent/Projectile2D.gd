extends StaticBody2D
class_name Projectile2D
## Projectiles are created and controlled by a [ProjectileSynchronizerComponent]
## Projectiles may specify a [member skill_class], which will trigger the skill using any hit objects as the targets.
## By default projectiles only hit players and enemies.

signal hit_object(object: Node2D)
signal collisions_exceeded

const NO_SKILL: String = ""
const NODE_GROUP_BASE: String = "_ProjectileGroup"

@export var projectile_class: String = ""
@export var skill_class: String = NO_SKILL
@export var lifespan: float = 12.0
@export var instance_limit: int = 10
@export var collision_scene: PackedScene

@export_group("Physics")
@export var move_speed: float = 100
@export var max_collisions: int = 1
@export var collide_with_other_projectiles: bool = false
@export var ignore_terrain: bool = false
@export var ignore_same_entity_type: bool = true

var target_global_pos: Vector2

var creation_time: float = Time.get_unix_time_from_system()

var moving: bool = false:
	set(val):
		moving = val
		set_physics_process(moving)

var collision_count: int = 0

var lifespan_timer := Timer.new()

## For containing metadata.
var misc: Dictionary

var required_misc_keys: Array[String]


func _init() -> void:
	collision_layer = J.PHYSICS_LAYER_PROJECTILE
	collision_mask = J.PHYSICS_LAYER_ENEMIES


func _physics_process(_delta: float) -> void:
	if not moving:
		return

	var motion: Vector2 = get_motion()

	process_collisions(motion * _delta)


func process_collisions(motion: Vector2):
	var current_motion: Vector2 = motion
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape_params := PhysicsShapeQueryParameters2D.new()

	shape_params.collide_with_areas = true
	shape_params.collision_mask = collision_mask
	shape_params.motion = current_motion
	shape_params.shape = $CollisionShape2D.shape
	shape_params.transform = transform
	for excepted: PhysicsBody2D in get_collision_exceptions():
		shape_params.exclude.append(excepted.get_rid())

	var collisions: Array[Dictionary] = space_state.intersect_shape(shape_params, max_collisions)
	for coll: Dictionary in collisions:
		if coll.get("collider") is Node2D:
			hit_object.emit(coll.get("collider"))
			collision_count += 1

			if collision_count >= max_collisions:
				collision_mask = 0
				collision_layer = 0
				queue_free.call_deferred()
				break

	position += current_motion

	# The followiong code has been temporarily disabled due to an engine bug (https://github.com/godotengine/godot/issues/76222)
	#while current_motion.length() > 0 and collision_count < max_collisions:
	#
	#var collision: KinematicCollision2D = move_and_collide(current_motion)
	#
	#if collision == null:
	#GodotLogger.error("Failed at retrieving collision result. Possible engine bug.")
	#continue


#
#if collision.get_collider() is Node2D:
#hit_object.emit(collision.get_collider())
#collision_count += 1
#
#current_motion = collision.get_remainder()


## This function may be overriden to change how the projectile moves
func get_motion() -> Vector2:
	return Vector2.RIGHT * move_speed


func launch(global_pos: Vector2):
	collision_count = 0
	set_launch_target(global_pos)
	set_moving(true)

	_launch()


func _launch():
	pass


func set_launch_target(global_pos: Vector2) -> Projectile2D:
	target_global_pos = global_pos
	return self


func set_moving(enable: bool = true) -> Projectile2D:
	moving = enable
	return self


func add_collision_mask(mask: int) -> Projectile2D:
	collision_mask = collision_mask | mask
	return self


func remove_collision_mask(mask: int) -> Projectile2D:
	collision_mask = collision_mask & ~mask
	return self


func add_node_to_ignored(node: Node) -> Projectile2D:
	add_collision_exception_with(node)
	return self


func remove_node_from_ignored(node: Node) -> Projectile2D:
	remove_collision_exception_with(node)
	return self


func clear_ignored_nodes() -> Projectile2D:
	for body: PhysicsBody2D in get_collision_exceptions():
		remove_node_from_ignored(body)
	return self


func set_lifespan(new_span: float) -> Projectile2D:
	# If the timer is already running, update it.
	if lifespan_timer.is_inside_tree():
		lifespan_timer.start(new_span)

	lifespan = new_span
	return self


func set_misc_data(key: String, data) -> Projectile2D:
	misc[key] = data
	return self


func is_misc_data_valid(misc_data: Dictionary = misc) -> bool:
	return misc_data.has_all(required_misc_keys)
