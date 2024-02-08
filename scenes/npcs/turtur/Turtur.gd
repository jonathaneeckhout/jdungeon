extends NPC

@onready var shop: ShopSynchronizerComponent = $ShopSynchronizerComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _init():
	super()
	npc_class = "Turtur"


func _ready():
	super()

	# Server side
	if multiplayer_connection.is_server():
		shop.server_add_item("Axe", 10)
		shop.server_add_item("Sword", 10)
		shop.server_add_item("Club", 10)
		shop.server_add_item("IronShield", 10)

		shop.server_add_item("LeatherHelm", 10)
		shop.server_add_item("LeatherBody", 10)
		shop.server_add_item("LeatherArms", 10)
		shop.server_add_item("LeatherLegs", 10)

		shop.server_add_item("ChainMailHelm", 20)
		shop.server_add_item("ChainMailBody", 20)
		shop.server_add_item("ChainMailArms", 20)
		shop.server_add_item("ChainMailLegs", 20)

		shop.server_add_item("PlateHelm", 30)
		shop.server_add_item("PlateBody", 30)
		shop.server_add_item("PlateArms", 30)
		shop.server_add_item("PlateLegs", 30)

	else:
		animation_player.animation_started.connect(_on_animation_started)

		animation_player.play("Idle")

		shop.loaded.connect(_on_loaded)

	$InterfaceComponent.display_name = npc_class


func server_interact(player: Player):
	if player.get("peer_id") == null:
		GodotLogger.error("player node does not have the peer_id variable")
		return

	shop.server_sync_shop(player.peer_id)


func _on_animation_started(_anim_name: String):
	# animation_player.queue("Idle")
	var random_value = randf()
	if random_value < 0.7:
		# Play the "idle" animation.
		animation_player.queue("Idle")
	else:
		# Play the "smithing" animation.
		animation_player.queue("Smithing")


func _on_loaded():
	multiplayer_connection.client_player.shop.open_shop(name)
