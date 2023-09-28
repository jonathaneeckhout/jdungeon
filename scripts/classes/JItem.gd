extends StaticBody2D

class_name JItem

enum MODE { LOOT, ITEMSLOT }

@export var uuid: String = "":
	set(new_uuid):
		uuid = new_uuid
		name = new_uuid

@export var expire_time: float = 30.0

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ITEM
var item_class: String = ""

var expire_timer: Timer

var consumable: bool = false
var equipment: bool = false
var is_gold: bool = false

var drop_rate: float = 0.0

var amount: int = 1
var price: int = 0

var healing = 0

var equipment_slot: String = ""


func _init():
	# Disable physics by default
	collision_layer = 0

	collision_mask = 0


func _ready():
	if J.is_server():
		expire_timer = Timer.new()
		expire_timer.one_shot = true

		expire_timer.wait_time = expire_time
		expire_timer.timeout.connect(_on_expire_timer_timeout)
		add_child(expire_timer)


func start_expire_timer():
	expire_timer.start(expire_time)


func loot(player: JPlayerBody2D) -> bool:
	if player.inventory.add_item(self):
		# Reset your postion
		self.position = Vector2.ZERO
		# Just to be safe, stop the expire timer
		expire_timer.stop()
		# Remove yourself from the world items
		J.world.items.remove_child(self)

		return true

	return false


func use(player: JPlayerBody2D) -> bool:
	if consumable:
		if healing > 0:
			player.heal(player, healing)
		return true
	elif equipment:
		if player.equipment and player.equipment.equip_item(self):
			return true
		else:
			J.logger.info("%s could not equip item %s" % [player.name, item_class])
			return false
	else:
		J.logger.info("%s could not use item %s" % [player.name, item_class])
		return false


func _on_expire_timer_timeout():
	queue_free()
