extends StaticBody2D

class_name Item

enum MODE { LOOT, ITEMSLOT }

enum ITEM_TYPE { EQUIPMENT, CONSUMABLE, CURRENCY }

@export var uuid: String = "":
	set(new_uuid):
		uuid = new_uuid
		name = new_uuid

@export var expire_time: float = 60.0

var multiplayer_connection: MultiplayerConnection = null

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ITEM
var item_type: ITEM_TYPE = ITEM_TYPE.EQUIPMENT
var item_class: String = ""
var component_list: Dictionary = {}

var expire_timer: Timer

var drop_rate: float = 0.0

var amount: int = 1
var price: int = 0
var value: int = 0

var healing = 0

var equipment_slot: String = ""

var boost: Boost

@onready var lootarea: Area2D = $LootArea


func _init():
	multiplayer_connection = J.server_client_multiplayer_connection

	# Disable physics by default
	collision_layer = 0

	collision_mask = 0

	boost = Boost.new()


func _ready():
	# Make sure to set the layer to items
	lootarea.collision_layer = J.PHYSICS_LAYER_ITEMS
	# We're not interested in others
	lootarea.collision_mask = 0

	# Hiding the lootarea, else the player will be surrounded by collision shapes. Remove this line if you want to debug
	lootarea.hide()

	if multiplayer_connection.is_server():
		expire_timer = Timer.new()
		expire_timer.one_shot = true

		expire_timer.wait_time = expire_time
		expire_timer.timeout.connect(_on_expire_timer_timeout)
		add_child(expire_timer)


func start_expire_timer():
	expire_timer.start(expire_time)


func server_loot(player: Player) -> bool:
	if player.inventory.server_add_item(self):
		# Reset your postion
		self.position = Vector2.ZERO
		# Just to be safe, stop the expire timer
		expire_timer.stop()
		# Remove yourself from the world items
		multiplayer_connection.map.items.remove_child(self)

		return true

	return false


func server_use(player: Player) -> bool:
	match item_type:
		ITEM_TYPE.CONSUMABLE:
			if boost.hp > 0:
				player.stats.heal(self.name, boost.hp)
				return true
		ITEM_TYPE.EQUIPMENT:
			if player.equipment and player.equipment.server_equip_item(self):
				return true
			else:
				GodotLogger.info("%s could not equip item %s" % [player.name, item_class])
				return false
		_:
			GodotLogger.info("%s could not use item %s" % [player.name, item_class])
			return false

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
