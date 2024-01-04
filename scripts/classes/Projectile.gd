extends Node2D
class_name Projectile2D

signal hit_body(body: PhysicsBody2D)

@export_group("Physics")
@export var shape: Shape2D
@export var move_speed: float = 100
@export var max_collisions: int = 1
@export_flags_2d_physics var collision_mask: int = 0

var excluded_rids: Array[RID]

var moving: bool = false:
	set(val):
		moving = val
		set_physics_process(moving)

var collision_count: int = 0

var direct_space: PhysicsDirectSpaceState2D

func _enter_tree() -> void:
	direct_space = get_world_2d().direct_space_state


func _physics_process(delta: float) -> void:
	if not moving:
		return
	
	assert(shape is Shape2D)
		
	var motion: Vector2 = get_motion()
	var shape_cast_params := PhysicsShapeQueryParameters2D.new()
	shape_cast_params.collision_mask = collision_mask
	shape_cast_params.shape = shape
	shape_cast_params.motion = motion
	shape_cast_params.exclude = excluded_rids
	shape_cast_params.transform.origin = transform.origin
	
	var collisions: Array[Dictionary] = direct_space.intersect_shape(shape_cast_params)
	
	var can_continue: bool = process_collisions(collisions)
	position += motion
	
	if not can_continue:
		moving = false
		queue_free()
	
	
func process_collisions(collisions: Array[Dictionary]) -> bool:
	for collision: Dictionary in collisions:
		
		if collision_count >= max_collisions:
			return false
			
		var collider: Node = collision.get("collider", null)
		if collider is PhysicsBody2D:
			hit_body.emit(collider)
			collision_count += 1
	
	return true

func get_motion() -> Vector2:
	return Vector2.RIGHT * move_speed


func set_launch_direction(direction: Vector2) -> Projectile2D:
	rotation = get_angle_to(direction)
	return self
	

func set_moving(enable: bool = true) -> Projectile2D:
	moving = enable
	return self
	
	
func add_collision_mask_bit(bit: int) -> Projectile2D:
	collision_mask = collision_mask | J.PHYSICS_LAYER_ENEMIES
	return self

	
func remove_collision_mask_bit(bit: int) -> Projectile2D:
	collision_mask = collision_mask | ~J.PHYSICS_LAYER_PLAYERS
	return self


func add_rid_to_ignored(rid: RID) -> Projectile2D:
	excluded_rids.append(rid)
	return self
	
	
func remove_rid_from_ignored(rid: RID) -> Projectile2D:
	excluded_rids.erase(rid)
	return self


func clear_ignored_rid() -> Projectile2D:
	excluded_rids.clear()
	return self
