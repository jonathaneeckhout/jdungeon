extends NPC

@onready var wander_behavior: WanderBehaviorComponent = $WanderBehaviorCopmonent
@onready var avoidance_rays: AvoidanceRaysComponent = $AvoidanceRaysComponent
@onready var shop: ShopSynchronizerComponent = $ShopSynchronizerComponent


func _init():
	super()
	npc_class = "MilkLady"


func _ready():
	# Server side
	if J.is_server():
		shop.add_item("HealthPotion", 100)

		shop.add_item("Axe", 10000)
		shop.add_item("Sword", 5000)
		shop.add_item("Club", 300)

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
	# Client side
	else:
		# Behavior is not handeld on client's side
		wander_behavior.queue_free()
		# Behavior is not handeld on client's side
		avoidance_rays.queue_free()


func interact(player: Player):
	if player.get("peer_id") == null:
		J.logger.error("player node does not have the peer_id variable")
		return

	shop.open_shop(player.peer_id)
