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

var is_dead: bool = false


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

	idle_timer.start(randi_range(min_idle_time, max_idle_time))

	actor.synchronizer.died.connect(_on_died)


func _physics_process(_delta: float):
	if J.is_server():
		if is_dead:
			actor.velocity = Vector2.ZERO
		elif actor.position.distance_to(wander_target) > J.ARRIVAL_DISTANCE:
			actor.velocity = (
				actor.position.direction_to(wander_target) * actor.stats.movement_speed
			)
			actor.velocity = actor.avoidance_rays.find_avoidant_velocity(actor.stats.movement_speed)
			actor.move_and_slide()
			if actor.get_slide_collision_count() > 0:
				if colliding_timer.is_stopped():
					colliding_timer.start(MAX_COLLIDING_TIME)
			else:
				if !colliding_timer.is_stopped():
					colliding_timer.stop()

			actor.send_new_loop_animation("Move")

		elif idle_timer.is_stopped():
			idle_timer.start(randi_range(min_idle_time, max_idle_time))
			actor.velocity = Vector2.ZERO

			actor.send_new_loop_animation("Idle")

func find_random_spot(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _on_idle_timer_timeout():
	wander_target = find_random_spot(starting_postion, max_wander_distance)


func _on_colliding_timer_timeout():
	wander_target = find_random_spot(starting_postion, max_wander_distance)


func _on_died():
	is_dead = true

