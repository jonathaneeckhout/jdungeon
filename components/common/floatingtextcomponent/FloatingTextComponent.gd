extends Node2D

@export var stats_synchronizer: StatsSynchronizerComponent

@onready var floating_text_scene = preload("res://scenes/templates/FloatingText/FloatingText.tscn")

# The parent node
var _target_node: Node


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.multiplayer_connection.is_server():
		return

	stats_synchronizer.healed.connect(_on_healed)
	stats_synchronizer.got_hurt.connect(_on_got_hurt)


func _on_got_hurt(_from: String, damage: int):
	var text = floating_text_scene.instantiate()
	text.amount = damage
	text.type = text.TYPES.DAMAGE
	add_child(text)


func _on_healed(_from: String, healing: int):
	var text = floating_text_scene.instantiate()
	text.amount = healing
	text.type = text.TYPES.HEALING
	add_child(text)
