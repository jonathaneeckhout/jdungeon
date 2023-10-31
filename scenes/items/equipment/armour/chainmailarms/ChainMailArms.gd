extends Item


func _init():
	super()

	item_class = "ChainMailArms"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Arms"
	boost.defense = 2
