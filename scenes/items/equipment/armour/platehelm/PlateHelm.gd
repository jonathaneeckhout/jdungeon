extends Item


func _init():
	super()

	item_class = "PlateHelm"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Head"
	boost.defense = 3
