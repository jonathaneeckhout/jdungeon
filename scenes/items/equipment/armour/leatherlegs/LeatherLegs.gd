extends JItem


func _init():
	super()

	item_class = "LeatherLegs"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "Legs"
	
	equipment_boosts.append( JStats.Boost.create_addi_boost(uuid, JStats.Keys.DEFENSE, 1) )
