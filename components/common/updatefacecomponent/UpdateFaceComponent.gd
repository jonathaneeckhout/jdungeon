extends Node

class_name UpdateFaceComponent

signal direction_changed(original: bool)

@export var skeleton: Node2D
@export var action_synchronizer: ActionSynchronizerComponent
@export var player_synchronizer: PlayerSynchronizer

var target_node: Node

var original_scale: Vector2 = Vector2.ONE
var last_scale: Vector2 = Vector2.ONE


func _ready():
	# Disable the physics process until the ready function is done
	set_physics_process(false)

	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This component should not run on the server
	if target_node.multiplayer_connection.is_server():
		queue_free()
		return

	original_scale = skeleton.scale
	last_scale = original_scale

	if (
		player_synchronizer
		and target_node.get("peer_id") != null
		and target_node.multiplayer_connection.is_own_player(target_node)
	):
		player_synchronizer.attacked.connect(_on_attacked)
	if action_synchronizer:
		action_synchronizer.attacked.connect(_on_attacked)

	# Enable the physics process now the ready function is done
	set_physics_process(true)


func _physics_process(_delta):
	if not target_node.velocity.is_zero_approx():
		update_face_direction(target_node.velocity.x)


func update_face_direction(direction: float):
	if direction < 0:
		skeleton.scale = original_scale
	elif direction > 0:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)

	if last_scale != skeleton.scale:
		last_scale = skeleton.scale
		direction_changed.emit(original_scale == skeleton.scale)


func _on_attacked(direction: Vector2):
	update_face_direction(direction.x)
