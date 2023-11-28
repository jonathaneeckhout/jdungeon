extends NPC

@onready var shop: ShopSynchronizerComponent = $ShopSynchronizerComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _init():
	super()
	npc_class = "Turtur"


func _ready():
	# Server side
	if G.is_server():
		shop.add_item("Axe", 10000)
		shop.add_item("Sword", 5000)
		shop.add_item("Club", 300)
		shop.add_item("IronShield", 10000)

		shop.add_item("LeatherHelm", 100)
		shop.add_item("LeatherBody", 100)
		shop.add_item("LeatherArms", 100)
		shop.add_item("LeatherLegs", 100)

		shop.add_item("ChainMailHelm", 1000)
		shop.add_item("ChainMailBody", 1000)
		shop.add_item("ChainMailArms", 1000)
		shop.add_item("ChainMailLegs", 1000)

		shop.add_item("PlateHelm", 10000)
		shop.add_item("PlateBody", 10000)
		shop.add_item("PlateArms", 10000)
		shop.add_item("PlateLegs", 10000)

	else:
		animation_player.animation_started.connect(_on_animation_started)

		animation_player.play("Idle")

	$InterfaceComponent.display_name = npc_class


func interact(player: Player):
	if player.get("peer_id") == null:
		GodotLogger.error("player node does not have the peer_id variable")
		return

	shop.open_shop(player.peer_id)


func _on_animation_started(_anim_name: String):
	# animation_player.queue("Idle")
	var random_value = randf()
	if random_value < 0.7:
		# Play the "idle" animation.
		animation_player.queue("Idle")
	else:
		# Play the "smithing" animation.
		animation_player.queue("Smithing")
