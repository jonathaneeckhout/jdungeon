extends CharacterBody2D
class_name Projectile2D
## Projectiles are created and controlled by a [ProjectileSynchronizerComponent]
## Projectiles may specify a [member skill_class], which will trigger the skill using any hit objects as the targets.
## By default projectiles only hit players and enemies.

signal hit_object(object: Node2D)

const NO_SKILL: String = ""

@export var projectile_class: String = ""
@export var skill_class: String = NO_SKILL
@export var lifespan: float = 12.0

@export var collision_scene: PackedScene

@export_group("Physics")
@export var move_speed: float = 100
@export var max_collisions: int = 1
@export var ignore_terrain: bool = false
@export var ignore_same_entity_type: bool = true

var target_global_pos: Vector2

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
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = J.PHYSICS_LAYER_PROJECTILE
	collision_mask = J.PHYSICS_LAYER_ENEMIES | J.PHYSICS_LAYER_PLAYERS


func _ready() -> void:
	add_child(lifespan_timer)
	lifespan_timer.timeout.connect(queue_free)
	lifespan_timer.start(lifespan)


func _physics_process(_delta: float) -> void:
	if not moving:
		return

	var motion: Vector2 = get_motion()

	process_collisions(motion)


func process_collisions(motion: Vector2):
	var current_motion: Vector2 = motion

	while current_motion.length() > 0 and collision_count < max_collisions:
		var collision: KinematicCollision2D = move_and_collide(current_motion)

		if collision.get_collider() is Node2D:
			hit_object.emit(collision.get_collider())
			collision_count += 1

		current_motion = collision.get_remainder()


## This function may be overriden to change how the projectile moves
func get_motion() -> Vector2:
	# Extend the target to ensure it keeps moving.
	target_global_pos = global_position.direction_to(target_global_pos) * move_speed * 2

	return global_position.direction_to(target_global_pos) * move_speed


func launch(global_pos: Vector2):
	set_launch_target(global_pos)
	set_moving(true)


func set_launch_target(global_pos: Vector2) -> Projectile2D:
	target_global_pos = global_pos
	return self


func set_moving(enable: bool = true) -> Projectile2D:
	moving = enable
	return self


func add_collision_mask_bit(bit: int) -> Projectile2D:
	set_collision_layer_value(bit, true)
	return self


func remove_collision_mask_bit(bit: int) -> Projectile2D:
	set_collision_layer_value(bit, false)
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
