extends JItem


func _init():
	super()

	item_class = "LeatherArms"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "Arms"

	equipment_boosts.append( JStats.Boost.create_addi_boost(uuid, JStats.Keys.DEFENSE, 1) )
