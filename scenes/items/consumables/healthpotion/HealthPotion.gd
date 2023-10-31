extends Item


func _init():
	super()

	item_class = "HealthPotion"
	item_type = ITEM_TYPE.CONSUMABLE
	boost.hp = 25
