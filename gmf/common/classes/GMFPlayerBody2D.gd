extends GMFBody2D

class_name GMFPlayerBody2D

var peer_id: int = 1
var username: String = ""

var player_synchronizer: GMFPlayerSynchronizer
var player_input: GMFPlayerInput
var player_behavior: GMFPlayerBehavior


func _init():
	entity_type = Gmf.ENTITY_TYPE.PLAYER


func _ready():
	super()

	collision_layer += Gmf.PHYSICS_LAYER_PLAYERS

	player_synchronizer = load("res://gmf/common/classes/GMFPlayerSynchronizer.gd").new()
	player_synchronizer.name = "PlayerSynchronizer"
	player_synchronizer.player = self
	player_synchronizer.synchronizer = synchronizer
	add_child(player_synchronizer)

	if Gmf.is_server():
		player_behavior = load("res://gmf/common/classes/behaviors/GMFPlayerBehavior.gd").new()
		player_behavior.name = "PlayerBehavior"
		player_behavior.player = self
		player_behavior.player_synchronizer = player_synchronizer
		player_behavior.player_stats = stats
		add_child(player_behavior)

	else:
		player_input = load("res://gmf/common/classes/GMFPlayerInput.gd").new()
		player_input.name = "PlayerInput"
		add_child(player_input)

		player_input.move.connect(_on_move)
		player_input.interact.connect(_on_interact)


func _on_move(target_position: Vector2):
	player_synchronizer.move.rpc_id(1, target_position)


func _on_interact(target_name: String):
	player_synchronizer.interact.rpc_id(1, target_name)
