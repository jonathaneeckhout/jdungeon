extends JItem


func _init():
	super()

	item_class = "Sword"
	itemType = ItemTypes.EQUIPMENT
	equipment_slot = "RightHand"
	
	
	var newBoost:=JStats.Boost.new()
	newBoost.statKey = JStats.Keys.ATTACK_DAMAGE
	newBoost.value = 10
	newBoost.type = JStats.Boost.Types.ADDITIVE
	newBoost.stackSource = uuid
	
	equipment_boosts.append(newBoost)
