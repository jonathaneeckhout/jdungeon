extends Node2D

class_name AttackAndWanderBehaviorComponent

## The stats sychronizer used to check if the parent node is dead or not
@export var stats_component: StatsSynchronizerComponent

## The action synchronzer used to sync the attack animation to other players
@export var action_synchronizer: ActionSynchronizerComponent

## This is the area used to detect players
@export var aggro_area: Area2D = null

## The minimum time the parent will stay idle
@export var min_idle_time: int = 3

## The maximum time the parent will stay idle
@export var max_idle_time: int = 10

## The maximum distance the parent should wander off to
@export var max_wander_distance: float = 256.0

# The parent node
var _target_node: Node

## The avoidance ray component is used to detect obstacles ahead
@onready var avoidance_rays_component: AvoidanceRaysComponent = $AvoidanceRaysComponent

# The component used to handle the wandering
@onready var _wander_component: WanderComponent = $WanderComponent

# The component used to handle the wandering
@onready var _aggro_component: AggroComponent = $AggroComponent


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

	# Don't aggro if the player is dead
	elif _aggro_component.current_target and _aggro_component.current_target.stats.is_dead:
		_aggro_component.select_first_alive_target()

	# If a player is in range, go after him
	elif _aggro_component.current_target:
		_aggro_component.aggro()

	# If no player is in range, wander around
	else:
		_wander_component.wander()
