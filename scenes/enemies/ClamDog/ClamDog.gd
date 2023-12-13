extends Enemy

@onready var loot: LootComponent = $LootComponent


func _init():
	super()
	enemy_class = "ClamDog"


func _ready():
	super()

	$InterfaceComponent.display_name = enemy_class

	if G.is_server():
		_add_loot()


func _add_loot():
	loot.add_item_to_loottable("Gold", 0.75, 100)
	loot.add_item_to_loottable("HealthPotion", 0.5, 1)
