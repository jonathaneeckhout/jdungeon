extends Node

class_name JShop

@export var size: int = 1

var inventory: Array[Dictionary] = []


func add_item(item_class: String, price: int) -> bool:
	if inventory.size() >= size:
		return false

	var item = {
		"uuid": J.uuid_util.v4(),
		"class": item_class,
		"price": price,
	}

	inventory.append(item)

	return true


func get_output():
	return {"inventory": inventory}
