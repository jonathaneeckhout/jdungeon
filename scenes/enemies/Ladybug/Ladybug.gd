extends Enemy


func _init():
	super()
	enemy_class = "Ladybug"


func _ready():
	super()

	$InterfaceComponent.display_name = enemy_class
