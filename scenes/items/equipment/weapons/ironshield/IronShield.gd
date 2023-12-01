extends Item


func _init():
	super()

	item_class = "IronShield"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "LeftHand"
	boost.defense = 3
