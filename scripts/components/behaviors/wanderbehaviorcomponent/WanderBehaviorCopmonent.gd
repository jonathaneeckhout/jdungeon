extends Node2D

class_name WanderBehaviorComponent

const RAY_SIZE = 64
const RAY_ANGLE = 30
const MAX_COLLIDING_TIME = 1.0

@export var stats_component: StatsSynchronizerComponent
@export var avoidance_rays_component: AvoidanceRaysComponent
@export var max_wander_distance: float = 256.0
@export var min_idle_time: int = 3
@export var max_idle_time: int = 10

var target_node: Node

var starting_postion: Vector2
var wander_target: Vector2

var idle_timer: Timer
var colliding_timer: Timer


func _ready():
	target_node = get_parent()

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return
	if target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if not stats_component:
		GodotLogger.error("Please connect a StatsComponent to this node")
		return

	starting_postion = target_node.position
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


func _physics_process(_delta: float):
	if G.is_server():
		if stats_component.is_dead:
			target_node.velocity = Vector2.ZERO
		elif target_node.position.distance_to(wander_target) > J.ARRIVAL_DISTANCE:
			target_node.velocity = (
				target_node.position.direction_to(wander_target) * stats_component.movement_speed
			)
			target_node.velocity = avoidance_rays_component.find_avoidant_velocity(
				stats_component.movement_speed
			)
			target_node.move_and_slide()
			if target_node.get_slide_collision_count() > 0:
				if colliding_timer.is_stopped():
					colliding_timer.start(MAX_COLLIDING_TIME)
			else:
				if !colliding_timer.is_stopped():
					colliding_timer.stop()
		elif idle_timer.is_stopped():
			idle_timer.start(randi_range(min_idle_time, max_idle_time))
			target_node.velocity = Vector2.ZERO


func find_random_spot(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _on_idle_timer_timeout():
	wander_target = find_random_spot(starting_postion, max_wander_distance)


func _on_colliding_timer_timeout():
	wander_target = find_random_spot(starting_postion, max_wander_distance)
