extends Enemy


func _init():
	super()
	enemy_class = "WildBoar"


func _ready():
	super()

	$InterfaceComponent.display_name = enemy_class
