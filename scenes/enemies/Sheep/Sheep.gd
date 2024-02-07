extends Enemy

@onready var loot: LootComponent = $LootComponent


func _init():
	super()
	enemy_class = "Sheep"


func _ready():
	super()

	$InterfaceComponent.display_name = enemy_class

	if multiplayer_connection.is_server():
		_add_loot()


func _add_loot():
	loot.add_item_to_loottable("Gold", 0.5, 20)
