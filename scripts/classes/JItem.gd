extends StaticBody2D

class_name JItem

enum MODE { LOOT, ITEMSLOT }

enum ItemTypes { EQUIPMENT, CONSUMABLE, CURRENCY}

signal uuid_changed(new_uuid: String)

var itemType: ItemTypes

@export var uuid: String = "":
	set(new_uuid):
		uuid = new_uuid
		name = new_uuid
		uuid_changed.emit(uuid)

@export var expire_time: float = 60.0

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ITEM
var item_class: String = ""

var expire_timer: Timer

var drop_rate: float = 0.0

var amount: int = 1
var price: int = 0
var value: int = 0

var healing = 0

var equipment_slot: String = ""

var equipment_boosts: Array[JStats.Boost]


func _init():
	# Disable physics by default
	collision_layer = 0
	collision_mask = 0
	
	#Keep all boosts with the same uuid as the item that owns them.
	uuid_changed.connect(update_boost_source)

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
	match itemType:
		ItemTypes.CONSUMABLE:
			if healing > 0:
				player.heal(player, healing)
				return true
		
		ItemTypes.EQUIPMENT:
			if player.equipment and player.equipment.equip_item(self):
				return true
			else:
				J.logger.info("%s could not equip item %s" % [player.name, item_class])
			return false
		
		_:
			J.logger.info("%s could not use item %s" % [player.name, item_class])

	return false



func to_json() -> Dictionary:
	return {"uuid": uuid, "item_class": item_class, "amount": amount}


func from_json(data: Dictionary) -> bool:
	uuid = data["uuid"]
	item_class = data["item_class"]
	amount = data["amount"]

	return true


func _on_expire_timer_timeout():
	queue_free()

func update_boost_source(newUuid: String):
	for boost in equipment_boosts:
		boost.stackSource = newUuid
