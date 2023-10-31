extends Item


func _init():
	super()

	item_class = "LeatherLegs"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Legs"
	boost.defense = 1
