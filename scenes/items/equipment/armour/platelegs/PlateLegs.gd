extends Item


func _init():
	super()

	item_class = "PlateLegs"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Legs"
	boost.defense = 3
