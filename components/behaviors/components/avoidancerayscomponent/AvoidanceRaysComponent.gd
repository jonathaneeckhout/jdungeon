extends Node2D

class_name AvoidanceRaysComponent

@export var ray_magnitude := 64
@export var ray_separation_angle := 30

var ray_front: RayCast2D = null
var ray_left_0: RayCast2D = null
var ray_left_1: RayCast2D = null
var ray_right_0: RayCast2D = null
var ray_right_1: RayCast2D = null

# The parent behavior node of this wander component
var _parent: Node = null

# The actor for this wander component
var _target_node: Node = null


func _ready():
	# Get the parent node
	_parent = get_parent()

	# This Node should run one level deeper than the behavior component
	_target_node = _parent.get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This node should only run the server side
	if not _target_node.multiplayer_connection.is_server():
		set_physics_process(false)
		queue_free()

	if _target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	ray_front = $RayFront
	ray_left_0 = $RayLeft0
	ray_left_1 = $RayLeft1
	ray_right_0 = $RayRight0
	ray_right_1 = $RayRight1

	_set_ray_targets()
	_set_ray_angles()


# Set the size of the rays
func _set_ray_targets():
	ray_front.target_position = Vector2(ray_magnitude, 0)
	ray_left_0.target_position = Vector2(ray_magnitude / 1.5, 0)
	ray_left_1.target_position = Vector2(ray_magnitude / 2.0, 0)
	ray_right_0.target_position = Vector2(ray_magnitude / 1.5, 0)
	ray_right_1.target_position = Vector2(ray_magnitude / 2.0, 0)


# Set the angle of the rays
func _set_ray_angles():
	ray_left_0.rotation_degrees = -ray_separation_angle
	ray_left_1.rotation_degrees = ray_separation_angle * -2
	ray_right_0.rotation_degrees = ray_separation_angle
	ray_right_1.rotation_degrees = ray_separation_angle * 2


func find_avoidant_velocity(velocity_multiplier: float) -> Vector2:
	# Rotate the rays towards the players velocity
	self.rotation = _target_node.velocity.angle()

	var avoidant_velocity: Vector2 = _target_node.velocity

	if _get_viable_ray():
		var viable_ray = _get_viable_ray()
		if viable_ray:
			avoidant_velocity = (
				Vector2.RIGHT.rotated(self.rotation + viable_ray.rotation) * velocity_multiplier
			)
	return avoidant_velocity


func move_with_avoidance(speed: float):
	# Find the optimal velocity
	_target_node.velocity = find_avoidant_velocity(speed)

	# Actually perform a move and slide
	_target_node.move_and_slide()


func _get_viable_ray() -> RayCast2D:
	for ray in self.get_children():
		if !ray.is_colliding():
			return ray
	return null
