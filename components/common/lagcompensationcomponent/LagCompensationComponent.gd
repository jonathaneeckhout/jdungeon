extends Node2D

## The current supported collision shapes for lag compensation
enum HURTBOXSHAPE { Circle, Capsule }

## The window size of how long an element should stay in the positionBuffer
const POSITION_BUFFER_TIME_WINDOW: float = 1.0

@export var hurt_box: CollisionShape2D = null

# The node on which this component will work on
var _target_node: Node = null

# The buffer containing all the positions inside the PositionBufferTimeWindow
var _position_buffer: Array[PositionElement] = []

# The shape of the hurtbox of the target node
var _hurtbox_shape: HURTBOXSHAPE = HURTBOXSHAPE.Circle

# The radius of the hurtbox shape (used for circle and capsule shape)
var _hurtbox_radius = 0.0

# The height of the hurtbox shape (used only for the capsule shape)
var _hurtbox_height = 0.0


func _ready():
	# Get the parent node
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This component should only run on the server-side
	if not _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	# Register the component in the parent's component_list
	if _target_node.get("component_list") != null:
		_target_node.component_list["lag_compensation"] = self

	if hurt_box.shape is CircleShape2D:
		_hurtbox_shape = HURTBOXSHAPE.Circle

		_hurtbox_radius = hurt_box.shape.radius

	elif hurt_box.shape is CapsuleShape2D:
		_hurtbox_shape = HURTBOXSHAPE.Capsule

		_hurtbox_radius = hurt_box.shape.radius
		_hurtbox_height = hurt_box.shape.height
	else:
		GodotLogger.error("The lag compensation hurtbox is using an unsupported shape")


func _physics_process(_delta):
	var timestamp: float = Time.get_unix_time_from_system()

	var threshold_timestamp = timestamp - POSITION_BUFFER_TIME_WINDOW

	var element: PositionElement = PositionElement.new()
	element.timestamp = timestamp
	element.position = _target_node.position

	_position_buffer.append(element)

	while _position_buffer.size() > 1 and _position_buffer[0].timestamp < threshold_timestamp:
		_position_buffer.remove_at(0)


func IsCircleCollidingWithTargetAtTimestamp(
	timestamp: float, circle_position: Vector2, circle_radius: float
) -> bool:
	var element_at_timestamp: PositionElement = get_closest_target_position_to_timestamp(timestamp)

	# If it does not exist, the collision did not happen
	if element_at_timestamp == null:
		return false

	var colliding: bool = false

	# Calculate the actual position of the collisionshape as it can have an offset
	var collision_shape_postion: Vector2 = element_at_timestamp.position + hurt_box.position

	# Check the collision according to the shape of the HurtBox
	match _hurtbox_shape:
		HURTBOXSHAPE.Circle:
			colliding = check_circle_collision(
				collision_shape_postion, circle_position, circle_radius
			)
		HURTBOXSHAPE.Capsule:
			colliding = check_capsule_collision(
				collision_shape_postion, circle_position, circle_radius
			)

	return colliding


# Check the collision between 2 circles
func check_circle_collision(
	target_node_position: Vector2, circle_position: Vector2, circle_radius: float
) -> bool:
	return target_node_position.distance_to(circle_position) < circle_radius + _hurtbox_radius


# Check the collision between a circle and a capsule
# A limitation is that the capsule should not be rotated or only 90 degree or the simple Y check does not work
func check_capsule_collision(
	targetNodePosition: Vector2, circle_position: Vector2, circle_radius: float
) -> bool:
	var distance_to_line: float = 0.0

	# Calculate the distance between the circle's center and the capsule's central line according to the rotation
	if hurt_box.rotation_degrees == 0.0:
		distance_to_line = abs(targetNodePosition.y - circle_position.y)
	elif abs(hurt_box.rotation_degrees) - 90.0 < 0.1:
		distance_to_line = abs(targetNodePosition.x - circle_position.x)
	else:
		GodotLogger.warn("HurtBox has an invalid rotation")
		return false

	# Calculate the distance between the circle's center and the closest point on the capsule's central line
	var distance_to_closest_point: float = distance_to_line - _hurtbox_height / 2

	# Check if the circle is within the range of the capsule's height
	if distance_to_closest_point > _hurtbox_height / 2:
		return false

	# Check if the circle is within the combined radius of the capsule and the circle
	var combined_radius: float = _hurtbox_radius + circle_radius
	return distance_to_closest_point <= combined_radius


# Find the position in the positionBuffer closest to the given timestamp
func get_closest_target_position_to_timestamp(timestamp: float) -> PositionElement:
	# If the buffer is invalid return null
	if _position_buffer == null or _position_buffer.size() == 0:
		return null

	# Init the closestElement with the first element of the buffer
	var closest_element: PositionElement = _position_buffer[0]

	# Calculate the time difference between the element and the given timestamp
	var min_time_difference: float = abs(timestamp - closest_element.timestamp)

	# Iterate over the position buffer
	for element in _position_buffer:
		# Calculate the diff for each element
		var time_difference: float = abs(timestamp - element.timestamp)

		# Update the closest when the difference is smaller
		if time_difference < min_time_difference:
			closest_element = element
			min_time_difference = time_difference

	# Return the closest element
	return closest_element


class PositionElement:
	extends RefCounted
	var timestamp: float
	var position: Vector2
