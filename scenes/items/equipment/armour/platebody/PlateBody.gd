extends Item


func _init():
	super()

	item_class = "PlateBody"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Body"
	boost.defense = 3
