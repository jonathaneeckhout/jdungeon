extends Node2D

class_name JWanderBehavior

const RAY_SIZE = 64
const RAY_ANGLE = 30
const MAX_COLLIDING_TIME = 1.0

@export var actor: JBody2D
@export var max_wander_distance: float = 256.0
@export var min_idle_time: int = 3
@export var max_idle_time: int = 10

var starting_postion: Vector2
var wander_target: Vector2

var idle_timer: Timer
var colliding_timer: Timer

var rays: Node2D
var ray_direction: RayCast2D


func _ready():
	starting_postion = actor.position
	wander_target = starting_postion

	idle_timer = Timer.new()
	idle_timer.one_shot = true
	idle_timer.name = "IdleTimer"
	idle_timer.timeout.connect(_on_idle_timer_timeout)
	add_child(idle_timer)

	colliding_timer = Timer.new()
	colliding_timer.one_shot = true
	colliding_timer.name = "CollidingTimer"
	add_child(colliding_timer)
	colliding_timer.timeout.connect(_on_colliding_timer_timeout)

	rays = Node2D.new()
	ray_direction = RayCast2D.new()

	init_avoidance_rays()

	idle_timer.start(randi_range(min_idle_time, max_idle_time))

	ray_direction.target_position = Vector2(RAY_SIZE, 0)
	add_child(ray_direction)


func _physics_process(_delta: float):
	if J.is_server():
		if actor.position.distance_to(wander_target) > J.ARRIVAL_DISTANCE:
			actor.velocity = (
				actor.position.direction_to(wander_target) * actor.stats.movement_speed
			)
			_move_with_avoidance()
			if actor.get_slide_collision_count() > 0:
				if colliding_timer.is_stopped():
					colliding_timer.start(MAX_COLLIDING_TIME)
			else:
				if !colliding_timer.is_stopped():
					colliding_timer.stop()
			ray_direction.rotation = actor.velocity.angle()

			actor.send_new_loop_animation("Move")

		elif idle_timer.is_stopped():
			idle_timer.start(randi_range(min_idle_time, max_idle_time))
			actor.velocity = Vector2.ZERO

			actor.send_new_loop_animation("Idle")


func init_avoidance_rays():
	rays.name = "Rays"

	var ray_front = RayCast2D.new()
	var ray_left_0 = RayCast2D.new()
	var ray_left_1 = RayCast2D.new()
	var ray_right_0 = RayCast2D.new()
	var ray_right_1 = RayCast2D.new()

	ray_front.enabled = true
	ray_left_0.enabled = true
	ray_left_1.enabled = true
	ray_right_0.enabled = true
	ray_right_1.enabled = true

	ray_front.name = "FrontRay"
	ray_left_0.name = "LeftRay0"
	ray_left_1.name = "LeftRay1"
	ray_right_0.name = "RightRay0"
	ray_right_1.name = "RightRay1"

	ray_front.target_position = Vector2(RAY_SIZE, 0)
	ray_left_0.target_position = Vector2(RAY_SIZE / 1.5, 0)
	ray_left_1.target_position = Vector2(RAY_SIZE / 2.0, 0)
	ray_right_0.target_position = Vector2(RAY_SIZE / 1.5, 0)
	ray_right_1.target_position = Vector2(RAY_SIZE / 2.0, 0)

	ray_left_0.rotation_degrees = -(1 * RAY_ANGLE)
	ray_left_1.rotation_degrees = -(2 * RAY_ANGLE)
	ray_right_0.rotation_degrees = 1 * RAY_ANGLE
	ray_right_1.rotation_degrees = 2 * RAY_ANGLE

	rays.add_child(ray_left_0)
	rays.add_child(ray_right_0)
	rays.add_child(ray_left_1)
	rays.add_child(ray_right_1)
	rays.add_child(ray_front)

	# rays.visible = false

	add_child(rays)


func _move_with_avoidance():
	rays.rotation = actor.velocity.angle()
	if _obstacle_ahead():
		var viable_ray = _get_viable_ray()
		if viable_ray:
			actor.velocity = (
				Vector2.RIGHT.rotated(rays.rotation + viable_ray.rotation)
				* actor.stats.movement_speed
			)
			actor.move_and_slide()
	else:
		actor.move_and_slide()


func _obstacle_ahead() -> bool:
	for ray in rays.get_children():
		if ray.is_colliding():
			return true

	return false


func _get_viable_ray() -> RayCast2D:
	for ray in rays.get_children():
		if !ray.is_colliding():
			return ray
	return null


func find_random_spot(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _on_idle_timer_timeout():
	wander_target = find_random_spot(starting_postion, max_wander_distance)


func _on_colliding_timer_timeout():
	wander_target = find_random_spot(starting_postion, max_wander_distance)
