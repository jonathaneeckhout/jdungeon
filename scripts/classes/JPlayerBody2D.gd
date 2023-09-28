extends JBody2D

class_name JPlayerBody2D

var peer_id: int = 1
var username: String = ""

var player_synchronizer: JPlayerSynchronizer
var player_input: JPlayerInput
var player_behavior: JPlayerBehavior
var inventory: JInventory
var equipment: JEquipment


func _init():
	entity_type = J.ENTITY_TYPE.PLAYER


func _ready():
	super()

	collision_layer += J.PHYSICS_LAYER_PLAYERS

	player_synchronizer = JPlayerSynchronizer.new()
	player_synchronizer.name = "PlayerSynchronizer"
	player_synchronizer.player = self
	player_synchronizer.synchronizer = synchronizer
	add_child(player_synchronizer)

	inventory = JInventory.new()
	inventory.name = "Inventory"
	inventory.player = self
	add_child(inventory)

	equipment = JEquipment.new()
	equipment.name = "Equipment"
	equipment.player = self
	add_child(equipment)

	if J.is_server():
		player_behavior = JPlayerBehavior.new()
		player_behavior.name = "PlayerBehavior"
		player_behavior.player = self
		player_behavior.player_synchronizer = player_synchronizer
		player_behavior.player_stats = stats
		add_child(player_behavior)

	else:
		player_input = JPlayerInput.new()
		player_input.name = "PlayerInput"
		add_child(player_input)

		player_input.move.connect(_on_move)
		player_input.interact.connect(_on_interact)


func _on_move(target_position: Vector2):
	player_synchronizer.move.rpc_id(1, target_position)


func _on_interact(target_name: String):
	player_synchronizer.interact.rpc_id(1, target_name)
