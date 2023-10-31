extends Item


func _init():
	super()

	item_class = "LeatherBody"
	item_type = ITEM_TYPE.EQUIPMENT
	equipment_slot = "Body"
	boost.defense = 1
