extends ConditionLeaf

@onready var wander_radius: float = get_parent().wander_radius

var spawn_position := Vector2.ZERO
var wander_destination := Vector2.ZERO


func tick(actor: Node, blackboard: Blackboard):
	if spawn_position == Vector2.ZERO:
		spawn_position = actor.spawn_position
	if not actor.destination_reached.is_connected(_destination_reached):
		actor.destination_reached.connect(_destination_reached)
	if wander_destination == Vector2.ZERO:
		actor.movement_multiplier = 1.0
		var stuck_destination = blackboard.get_value("stuck_destination")
		if stuck_destination != null:
			blackboard.erase_value("stuck_destination")
			wander_destination = Vector2(
				spawn_position.x * randf_range(0.85, 1.15),
				spawn_position.y * randf_range(0.85, 1.15)
			)
		else:
			wander_destination = _random_point_within_radius(actor, spawn_position, wander_radius)
		blackboard.set_value("destination_global_position", wander_destination)
	return SUCCESS


func _random_point_within_radius(actor: Node, origin: Vector2, distance: float) -> Vector2:
	var open_check := RayCast2D.new()
	actor.add_child(open_check)
	open_check.collision_mask = J.PHYSICS_LAYER_WORLD
	var dst: Vector2 = _make_rand_vector(origin, distance)
	open_check.target_position = dst
	while open_check.is_colliding():
		dst = _make_rand_vector(origin, distance)
	open_check.queue_free()
	return dst


func _make_rand_vector(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _destination_reached():
	wander_destination = Vector2.ZERO
