extends Item


func _init():
	super()

	item_class = "ChainMailLegs"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Legs"
	boost.defense = 2
