extends Node

@export var skeleton: Node2D
@export var action_synchronizer: ActionSynchronizerComponent
@export var player_synchronizer: PlayerSynchronizer

var target_node: Node

var original_scale: Vector2 = Vector2.ONE


func _ready():
	target_node = get_parent()
	original_scale = skeleton.scale

	if (
		player_synchronizer
		and target_node.get("peer_id") != null
		and target_node.peer_id == multiplayer.get_unique_id()
	):
		player_synchronizer.attacked.connect(_on_attacked)
	if action_synchronizer:
		action_synchronizer.attacked.connect(_on_attacked)


func _physics_process(_delta):
	if not target_node.velocity.is_zero_approx():
		update_face_direction(target_node.velocity.x)


func update_face_direction(direction: float):
	if direction < 0:
		skeleton.scale = original_scale
		return
	if direction > 0:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)
		return


func _on_attacked(direction: Vector2):
	update_face_direction(direction.x)
