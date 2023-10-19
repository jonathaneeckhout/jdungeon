extends JItem


func _init():
	super()

	item_class = "LeatherLegs"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "Legs"
	
	var newBoost:=JStats.Boost.new()
	newBoost.statKey = JStats.Keys.DEFENSE
	newBoost.value = 10
	newBoost.type = JStats.Boost.Types.ADDITIVE
	newBoost.stackSource = uuid
	
	equipment_boosts.append(newBoost)
