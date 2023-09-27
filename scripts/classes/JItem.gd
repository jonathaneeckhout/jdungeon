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
var is_gold: bool = false

var drop_rate: float = 0.0

var amount: int = 1

var healing = 0


func _ready():
	collision_layer = J.PHYSICS_LAYER_ITEMS

	collision_mask = 0

	if J.is_server():
		expire_timer = Timer.new()
		expire_timer.one_shot = true

		expire_timer.wait_time = expire_time
		expire_timer.timeout.connect(_on_expire_timer_timeout)
		add_child(expire_timer)


func start_expire_timer():
	expire_timer.start(expire_time)


func loot(from: JPlayerBody2D) -> bool:
	if from.inventory.add_item(self):
		# Just to be safe, stop the expire timer
		expire_timer.stop()
		# Remove yourself from the world items
		J.world.items.remove_child(self)

		return true

	return false


func use(user: JPlayerBody2D) -> bool:
	if consumable:
		if healing > 0:
			user.heal(user, healing)
		return true
	else:
		return false


func _on_expire_timer_timeout():
	queue_free()
