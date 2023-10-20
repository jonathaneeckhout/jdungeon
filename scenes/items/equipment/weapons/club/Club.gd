extends JItem


func _init():
	super()

	item_class = "Axe"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "RightHand"

	equipment_boosts.append( JStats.Boost.create_addi_boost(uuid, JStats.Keys.ATTACK_DAMAGE, 8) )
