extends Projectile2D


func _launch():
	global_position = target_global_pos


func get_motion():
	return Vector2.ZERO
