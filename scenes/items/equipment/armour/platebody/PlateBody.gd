extends JItem


func _init():
	super()

	item_class = "PlateBody"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "Body"

	equipment_boosts.append( JStats.Boost.create_addi_boost(uuid, JStats.Keys.DEFENSE, 3) )
