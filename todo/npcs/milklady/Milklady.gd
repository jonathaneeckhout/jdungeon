extends NPC

@onready var wander_behavior: WanderBehaviorComponent = $WanderBehaviorCopmonent
@onready var shop: ShopSynchronizerComponent = $ShopSynchronizerComponent


func _init():
	super()
	npc_class = "MilkLady"


func _ready():
	super()

	# Server side
	if G.is_server():
		shop.add_item("HealthPotion", 100)

	$InterfaceComponent.display_name = npc_class


func interact(player: Player):
	if player.get("peer_id") == null:
		GodotLogger.error("player node does not have the peer_id variable")
		return

	player.dialogue.sync_invoke(player.peer_id, npc_class)

	if not player.dialogue.dialogue_system_instance.dialogue_finished.is_connected(
		_on_dialogue_finished.bind(player.peer_id)
	):
		player.dialogue.dialogue_system_instance.dialogue_finished.connect(
			_on_dialogue_finished.bind(player.peer_id), CONNECT_ONE_SHOT
		)


func _on_dialogue_finished(peerID: int):
	shop.open_shop(peerID)
