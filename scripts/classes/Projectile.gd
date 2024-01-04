extends CharacterBody2D
class_name Projectile2D

signal hit_body(body: PhysicsBody2D)

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.PROJECTILE
var projectile_class: String = ""

@export var sync: bool = true
@export_group("Physics")
@export var shape: Shape2D
@export var move_speed: float = 100
@export var max_collisions: int = 1

var moving: bool = false:
	set(val):
		moving = val
		set_physics_process(moving)

var collision_count: int = 0


func _init() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = J.PHYSICS_LAYER_PROJECTILE
	collision_mask = 0


func _ready() -> void:
	if sync:
		pass


func _physics_process(delta: float) -> void:
	if not moving:
		return
	
	assert(shape is Shape2D)
		
	var motion: Vector2 = get_motion()
	
	process_collisions(motion)
	
	
func process_collisions(motion: Vector2):
	var current_motion: Vector2 = motion
	
	while current_motion.length() > 0 and collision_count < max_collisions:
		var collision: KinematicCollision2D = move_and_collide(current_motion)
		
		if collision.get_collider() is PhysicsBody2D:
			hit_body.emit(collision.get_collider())
			collision_count += 1
		
		current_motion = collision.get_remainder()
	

func get_motion() -> Vector2:
	return Vector2.RIGHT * move_speed


func set_launch_direction(direction: Vector2) -> Projectile2D:
	rotation = get_angle_to(direction)
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
