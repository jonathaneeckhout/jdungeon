extends JBody2D

class_name JNPCBody2D

var npc_class: String = ""

@export var is_vendor: bool = false

var shop: JShop


func _init():
	super()

	entity_type = J.ENTITY_TYPE.NPC

	collision_layer += J.PHYSICS_LAYER_NPCS

	if J.is_server():
		shop = JShop.new()
		shop.name = "Shop"
		add_child(shop)


func interact(player: JPlayerBody2D):
	if is_vendor:
		J.rpcs.npc.sync_shop.rpc_id(player.peer_id, npc_class, shop.to_json())
