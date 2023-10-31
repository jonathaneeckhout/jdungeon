extends Item


func _init():
	super()

	item_class = "Sword"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "RightHand"
	boost.attack_power_min = 8
	boost.attack_power_max = 10
