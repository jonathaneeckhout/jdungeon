extends JBody2D

class_name JNPCBody2D

@export var is_vendor: bool = false

var shop: JShop


func _ready():
	super()

	shop = JShop.new()
	shop.name = "Shop"
	add_child(shop)


func interact(who: JPlayerBody2D):
	pass
