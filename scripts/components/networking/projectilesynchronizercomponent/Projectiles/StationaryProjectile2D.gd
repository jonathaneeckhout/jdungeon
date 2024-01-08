extends Projectile2D

func _launch(global_pos: Vector2):
	global_position = global_pos

func get_motion():
	return Vector2.ZERO
