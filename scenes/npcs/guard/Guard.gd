extends NPC

@onready var wander_behavior: WanderBehaviorComponent = $WanderBehaviorCopmonent


func _init():
	super()
	npc_class = "Guard"


func _ready():
	super()

	$InterfaceComponent.display_name = npc_class
