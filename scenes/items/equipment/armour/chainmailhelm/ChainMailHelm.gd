extends JItem


func _init():
	super()

	item_class = "ChainMailHelm"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "Head"

	equipment_boosts.append( JStats.Boost.create_addi_boost(uuid, JStats.Keys.DEFENSE, 2) )
