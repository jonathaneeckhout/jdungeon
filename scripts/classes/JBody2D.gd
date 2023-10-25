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
	synchronizer = load("res://scripts/classes/JSynchronizer.gd").new()
	synchronizer.name = "Synchronizer"
	synchronizer.to_be_synced = self
	add_child(synchronizer)

	stats = load("res://scripts/classes/JStats.gd").new()
	stats.name = "Stats"
	stats.parent = self
	add_child(stats)

	#Call this at the last moment, prevents possible errors from non-ready collisions and allows overriden _init methods to run first.
	_init_collisions.call_deferred()


func _init_collisions():
	#Each creature only exists on their own layer, they collide with the world thanks to their collision_mask
	match entity_type:
		J.ENTITY_TYPE.PLAYER:
			collision_layer = J.PHYSICS_LAYER_PLAYERS
		J.ENTITY_TYPE.ENEMY:
			collision_layer = J.PHYSICS_LAYER_ENEMIES
		J.ENTITY_TYPE.NPC:
			collision_layer = J.PHYSICS_LAYER_NPCS

	if J.is_server():
		#By default, only collide with the world. No other entities.
		collision_mask = J.PHYSICS_LAYER_WORLD

		#Set what it will collide with
		match entity_type:
			#The player cannot walk past NPCs and enemies. But other players cannot block their path.
			J.ENTITY_TYPE.PLAYER:
				collision_mask += J.PHYSICS_LAYER_ENEMIES + J.PHYSICS_LAYER_NPCS

			#Enemies can be blocked by NPCs and players.
			J.ENTITY_TYPE.ENEMY:
				collision_mask += J.PHYSICS_LAYER_PLAYERS + J.PHYSICS_LAYER_NPCS

			#NPCs cannot be stopped by any entity.
			J.ENTITY_TYPE.NPC:
				collision_mask = 0
	else:
		# Don't handle collision on client side
		collision_mask = 0


func attack(target: CharacterBody2D):
	var damage = randi_range(stats.attack_power_min, stats.attack_power_max)

	target.hurt(self, damage)
	synchronizer.sync_attack(target.name, damage)


func hurt(from: CharacterBody2D, damage: int):
	var damage_done: int = stats.hurt(damage)

	synchronizer.sync_hurt(from.name, stats.hp, stats.max_hp, damage_done)

	# R.I.P. you're dead
	if stats.hp <= 0:
		if stats.experience_given > 0:
			from.stats.add_experience(name, stats.experience_given)

		# Can't die twice
		if not is_dead:
			die()


func heal(from: CharacterBody2D, healing: int):
	var healing_done: int = stats.heal(healing)

	synchronizer.sync_heal(from.name, stats.hp, stats.max_hp, healing_done)


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
