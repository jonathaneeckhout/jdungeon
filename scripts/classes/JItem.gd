extends StaticBody2D

class_name JItem

enum MODE { LOOT, ITEMSLOT }

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ITEM

var expire_timer: Timer
@export var expire_time: float = 30.0

var is_gold: bool = false
var drop_rate: float = 0.0
var amount: int = 1

var item_class: String = ""

var mode: MODE = MODE.LOOT:
	set(new_mode):
		mode = new_mode
		match new_mode:
			MODE.LOOT:
				$Sprite.visible = true
			MODE.ITEMSLOT:
				$Sprite.visible = false


func _ready():
	collision_layer = J.PHYSICS_LAYER_ITEMS

	collision_mask = 0

	if J.is_server():
		expire_timer = Timer.new()
		expire_timer.one_shot = true
		if mode == MODE.LOOT:
			expire_timer.autostart = true
		expire_timer.wait_time = expire_time
		expire_timer.timeout.connect(_on_expire_timer_timeout)
		add_child(expire_timer)


func _on_expire_timer_timeout():
	queue_free()
