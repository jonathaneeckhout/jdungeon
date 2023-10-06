extends CharacterBody2D

class_name JBody2D

signal died

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ENEMY

var synchronizer: JSynchronizer
var stats: JStats

var loop_animation: String = "Idle"

var loot_table: Array[Dictionary] = []


func _init():
	collision_layer = J.PHYSICS_LAYER_WORLD

	if J.is_server():
		collision_mask = J.PHYSICS_LAYER_WORLD
	else:
		# Don't handle collision on client side
		collision_mask = 0

	synchronizer = load("res://scripts/classes/JSynchronizer.gd").new()
	synchronizer.name = "Synchronizer"
	synchronizer.to_be_synced = self
	add_child(synchronizer)

	stats = load("res://scripts/classes/JStats.gd").new()
	stats.name = "Stats"
	stats.parent = self
	add_child(stats)


func attack(target: CharacterBody2D):
	var damage = randi_range(stats.attack_power_min, stats.attack_power_max)

	target.hurt(self, damage)
	synchronizer.sync_attack(target.name, damage)


func hurt(from: CharacterBody2D, damage: int):
	var damage_done: int = stats.hurt(damage)

	synchronizer.sync_hurt(from.name, stats.hp, stats.max_hp, damage_done)


func heal(from: CharacterBody2D, healing: int):
	var healing_done: int = stats.heal(healing)

	synchronizer.sync_heal(from.name, stats.hp, stats.max_hp, healing_done)


func send_new_loop_animation(animation: String):
	if loop_animation != animation:
		loop_animation = animation
		synchronizer.sync_loop_animation(loop_animation, velocity)


func die():
	collision_layer -= J.PHYSICS_LAYER_WORLD

	died.emit()

	synchronizer.sync_die()

	drop_loot()


func drop_loot():
	for loot in loot_table:
		if randf() < loot["drop_rate"]:
			var item = J.item_scenes[loot["item_class"]].instantiate()
			item.uuid = J.uuid_util.v4()
			item.item_class = loot["item_class"]
			item.amount = randi_range(1, loot["amount"])
			item.collision_layer = J.PHYSICS_LAYER_ITEMS

			var random_x = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
			var random_y = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
			item.position = position + Vector2(random_x, random_y)

			J.world.items.add_child(item)
			item.start_expire_timer()


func add_item_to_loottable(item_class: String, drop_rate: float, amount: int = 1):
	loot_table.append({"item_class": item_class, "drop_rate": drop_rate, "amount": amount})
