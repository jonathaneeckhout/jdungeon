extends JItem


func _init():
	super()

	item_class = "HealthPotion"
	itemType = ItemTypes.CONSUMABLE
	healing = 25
