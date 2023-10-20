extends CharacterBody2D

class_name JBody2D

signal died
signal respawned

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ENEMY
var synchronizer: JSynchronizer
var stats: JStats

var loop_animation: String = "Idle"
var loot_table: Array[Dictionary] = []
var is_dead := false


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


func _ready():
	if not J.is_server() and J.client.player:
		stats.sync_stats.rpc_id(1, J.client.player.peer_id)


func attack(information: AttackInformation):
	information.target.hurt( information.attacker, information.damage )
	synchronizer.sync_attack( information.target.get_name(),  information.damage )


func hurt(from: CharacterBody2D, damage: float):
	var damage_done: float = stats.hp_hurt(damage)

	synchronizer.sync_hurt(from.name, stats.hp, stats.hp_max, damage_done)

	# R.I.P. you're dead
	if stats.hp <= 0:
		if stats.experience_worth > 0:
			from.stats.experience_add(name, stats.experience_worth)

		# Can't die twice
		if not is_dead:
			die()


func heal(from: CharacterBody2D, healing: int):
	var healing_done: int = stats.hp_heal(healing)

	synchronizer.sync_heal(from.name, stats.hp, stats.hp_max, healing_done)


func send_new_loop_animation(animation: String):
	if loop_animation != animation:
		loop_animation = animation
		synchronizer.sync_loop_animation(loop_animation, velocity)


func die():
	is_dead = true
	collision_layer -= J.PHYSICS_LAYER_WORLD

	died.emit()

	synchronizer.sync_die()

	drop_loot()


func respawn(location: Vector2):
	position = location
	is_dead = false
	collision_layer += J.PHYSICS_LAYER_WORLD
	stats.reset_hp()

	respawned.emit()

	synchronizer.sync_respawn()


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

#This acts as a data container to enable more complex abilities later, which may need to know more than just the target
class AttackInformation extends Object:
	var attacker: JBody2D
	var target: JBody2D
	var damage: float
	var cooldownExpected: float
	
