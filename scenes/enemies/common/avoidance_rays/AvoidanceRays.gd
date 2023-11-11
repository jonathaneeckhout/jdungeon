extends Node2D

@export var ray_magnitude := 64
@export var ray_separation_angle := 30

@onready var ray_front := $RayFront
@onready var ray_left_0 := $RayLeft0
@onready var ray_left_1 := $RayLeft1
@onready var ray_right_0 := $RayRight0
@onready var ray_right_1 := $RayRight1

@onready var actor := self.get_parent()


func _ready():
	if G.is_server():
		_set_ray_targets()
		_set_ray_angles()
	else:
		self.visible = false


func _set_ray_targets():
	ray_front.target_position = Vector2(ray_magnitude, 0)
	ray_left_0.target_position = Vector2(ray_magnitude / 1.5, 0)
	ray_left_1.target_position = Vector2(ray_magnitude / 2.0, 0)
	ray_right_0.target_position = Vector2(ray_magnitude / 1.5, 0)
	ray_right_1.target_position = Vector2(ray_magnitude / 2.0, 0)


func _set_ray_angles():
	ray_left_0.rotation_degrees = -ray_separation_angle
	ray_left_1.rotation_degrees = ray_separation_angle * -2
	ray_right_0.rotation_degrees = ray_separation_angle
	ray_right_1.rotation_degrees = ray_separation_angle * 2


func find_avoidant_velocity(velocity_multiplier: float) -> Vector2:
	if G.is_server():
		self.rotation = actor.velocity.angle()
		var avoidant_velocity: Vector2 = actor.velocity
		if _get_viable_ray():
			var viable_ray = _get_viable_ray()
			if viable_ray:
				avoidant_velocity = (
					Vector2.RIGHT.rotated(self.rotation + viable_ray.rotation) * velocity_multiplier
				)
		return avoidant_velocity
	return Vector2.ZERO


func _get_viable_ray() -> RayCast2D:
	for ray in self.get_children():
		if !ray.is_colliding():
			return ray
	return null
