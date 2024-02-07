extends NPC


func _init():
	super()
	npc_class = "Fernand"


func _ready():
	super()

	$InterfaceComponent.display_name = npc_class


func interact(player: Player):
	if player.get("peer_id") == null:
		GodotLogger.error("player node does not have the peer_id variable")
		return

	player.dialogue.sync_invoke(player.peer_id, npc_class)
