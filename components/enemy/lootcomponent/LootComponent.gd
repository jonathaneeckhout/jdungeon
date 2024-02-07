extends Node

class_name LootComponent

@export var stats: StatsSynchronizerComponent
@export var drop_range: int = 64

var target_node: Node

var loot_table: Array[Dictionary] = []


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if not target_node.multiplayer_connection.is_server():
		return

	stats.died.connect(_on_died)


func drop_loot():
	for loot in loot_table:
		if randf() < loot["drop_rate"]:
			var item: Item = J.item_scenes[loot["item_class"]].instantiate()
			item.uuid = J.uuid_util.v4()
			item.item_class = loot["item_class"]
			item.amount = randi_range(1, loot["amount"])
			item.collision_layer = J.PHYSICS_LAYER_ITEMS

			var random_x = randi_range(-drop_range, drop_range)
			var random_y = randi_range(-drop_range, drop_range)
			item.position = target_node.position + Vector2(random_x, random_y)
			item.multiplayer_connection = target_node.multiplayer_connection

			target_node.multiplayer_connection.map.items.add_child(item)
			item.start_expire_timer()


func add_item_to_loottable(item_class: String, drop_rate: float, amount: int = 1):
	loot_table.append({"item_class": item_class, "drop_rate": drop_rate, "amount": amount})


func _on_died():
	drop_loot()
