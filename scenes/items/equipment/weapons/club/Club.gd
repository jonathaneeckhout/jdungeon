extends Item


func _init():
	super()

	item_class = "Axe"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "RightHand"
	boost.attack_power_min = 2
	boost.attack_power_max = 8
