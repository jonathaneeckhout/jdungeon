extends Projectile2D

var global_direction: Vector2


func _launch():
	global_direction = global_position.direction_to(target_global_pos)
	global_rotation = global_position.angle_to_point(target_global_pos)
	pass


func get_motion():
	return global_direction * move_speed
