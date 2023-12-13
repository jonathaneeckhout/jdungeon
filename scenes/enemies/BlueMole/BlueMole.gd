extends Enemy


func _init():
	super()
	enemy_class = "BlueMole"


func _ready():
	super()

	$InterfaceComponent.display_name = enemy_class
