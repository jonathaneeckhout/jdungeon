extends Node

@export var skeleton: Node2D

var target_node: Node

var original_scale: Vector2 = Vector2.ONE


func _ready():
	target_node = get_parent()
	original_scale = skeleton.scale


func _physics_process(_delta):
	update_face_direction(target_node.velocity.x)


func update_face_direction(direction: float):
	if direction < 0:
		skeleton.scale = original_scale
		return
	if direction > 0:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)
		return
