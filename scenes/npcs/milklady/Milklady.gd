extends NPCBody

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

	# Client side
	else:
		# Behavior is not handeld on client's side
		wander_behavior.queue_free()
		# Behavior is not handeld on client's side
		avoidance_rays.queue_free()

	$InterfaceComponent.display_name = npc_class


func interact(player: Player):
	if player.get("peer_id") == null:
		J.logger.error("player node does not have the peer_id variable")
		return

	shop.open_shop(player.peer_id)
