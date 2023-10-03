extends Node2D

class_name JFleeBehavior

@export var actor: JBody2D
@export var min_flee_time := 2.0
@export var max_flee_time := 4.0
@export var max_colliding_time := 1.0
@export var flee_speed_multiplier := 4.0

signal flee_complete
signal dead_end

var attacker_position: Vector2
var flee_target: Vector2

var flee_timer: Timer
var colliding_timer: Timer

func _init(target: Vector2):
    self.flee_target = target

func _ready():
    randomize()
    flee_timer = Timer.new()
    flee_timer.one_shot = true
    flee_timer.name = "FleeTimer"
    flee_timer.timeout.connect(_on_flee_timer_timeout)
    add_child(flee_timer)
    flee_timer.start(randf_range(min_flee_time, max_flee_time))
    
    actor.synchronizer.got_hurt.connect(_on_got_hurt)

    colliding_timer = Timer.new()
    colliding_timer.one_shot = true
    colliding_timer.name = "CollidingTimer"
    colliding_timer.timeout.connect(_on_colliding_timer_timeout)
    add_child(colliding_timer)

func _physics_process(_delta: float):
    if J.is_server():
        if actor.is_dead:
            actor.velocity = Vector2.ZERO
        elif actor.global_position.distance_to(flee_target) > J.ARRIVAL_DISTANCE:
            var velocity_multiplier := actor.stats.movement_speed * flee_speed_multiplier
            actor.velocity = (
                actor.global_position.direction_to(flee_target) * velocity_multiplier
            )
            actor.velocity = actor.avoidance_rays.find_avoidant_velocity(velocity_multiplier)
            actor.move_and_slide()
            if actor.get_slide_collision_count() > 0:
                if colliding_timer.is_stopped():
                    colliding_timer.start(max_colliding_time)
            else:
                if !colliding_timer.is_stopped():
                    colliding_timer.stop()
            actor.send_new_loop_animation("Move")

func _on_flee_timer_timeout():
    actor.synchronizer.got_hurt.disconnect(_on_got_hurt)
    flee_complete.emit()

func _on_colliding_timer_timeout():
    dead_end.emit()

func _on_got_hurt(_from: String, _hp: int, _max_hp: int, _damage: int):
    if !flee_timer.is_stopped():
        flee_timer.start(randf_range(min_flee_time, max_flee_time))