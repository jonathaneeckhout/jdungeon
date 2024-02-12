extends Node2D

class_name FleeAndWanderBehaviorComponent

## The stats sychronizer used to check if the parent node is dead or not
@export var stats_component: StatsSynchronizerComponent

## The minimum time the parent will stay idle
@export var min_idle_time: int = 3

## The maximum time the parent will stay idle
@export var max_idle_time: int = 10

## The maximum distance the parent should wander off to
@export var max_wander_distance: float = 256.0

## How much the speed of the should increase when fleeing
@export var flee_speed_boost: float = 3.0

# The parent node
var _target_node: Node

# The component used to handle the flee behavior
@onready var _flee_component: FleeComponent = $FleeComponent

# The component used to handle the wandering
@onready var _wander_component: WanderComponent = $WanderComponent

# The avoidance ray component is used to detect obstacles ahead
@onready var avoidance_rays_component: AvoidanceRaysComponent = $AvoidanceRaysComponent


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This node should only run the server side
	if not _target_node.multiplayer_connection.is_server():
		set_physics_process(false)
		queue_free()

	if _target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return
	if _target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the position variable")
		return


func _physics_process(_delta: float):
	_behavior()


func _behavior():
	# If the parent node is dead, don't do anything
	if stats_component.is_dead:
		_target_node.velocity = Vector2.ZERO
		return

	# Check if you should flee
	if _flee_component.fleeing:
		_flee_component.flee()

	# Else wander around
	else:
		_wander_component.wander()
