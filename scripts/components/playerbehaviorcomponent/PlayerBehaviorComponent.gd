extends Node2D

class_name PlayerBehaviorComponent

enum INTERACT_TYPE { ENEMY, NPC, ITEM }

@export var input_synchronizer: InputSynchronizerComponent
@export var stats_component: StatsSynchronizerComponent
@export var action_synchronizer: ActionSynchronizerComponent

var target_node: Node

var attack_timer: Timer

var enemies_in_attack_range: Array[Enemy] = []
var items_in_loot_range: Array[Item] = []
var npcs_in_interact_range: Array[NPC] = []

var moving: bool = false
var move_target: Vector2 = Vector2()

var interacting: bool = false
var interact_target: Variant = null
var interact_type: INTERACT_TYPE = INTERACT_TYPE.ENEMY


func _ready():
	target_node = get_parent()

	if target_node.get("position") == null:
		J.logger.error("target_node does not have the position variable")
		return

	if target_node.get("velocity") == null:
		J.logger.error("target_node does not have the position variable")
		return

	_init_attack_area()
	_init_loot_area()
	_init_interact_area()

	input_synchronizer.moved.connect(_on_moved)
	input_synchronizer.interacted.connect(_on_interacted)

	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)


func _init_attack_area():
	var attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0
	attack_area.collision_mask = J.PHYSICS_LAYER_ENEMIES

	var cs_attack_area = CollisionShape2D.new()
	cs_attack_area.name = "AttackAreaCollisionShape2D"
	attack_area.add_child(cs_attack_area)

	var cs_attack_area_circle = CircleShape2D.new()

	cs_attack_area_circle.radius = stats_component.attack_range
	cs_attack_area.shape = cs_attack_area_circle

	add_child(attack_area)

	attack_area.body_entered.connect(_on_attack_area_enemy_entered)
	attack_area.body_exited.connect(_on_attack_area_enemy_exited)


func _init_loot_area():
	var loot_area = Area2D.new()
	loot_area.name = "LootArea"
	loot_area.collision_layer = 0
	loot_area.collision_mask = J.PHYSICS_LAYER_ITEMS

	var cs_loot_area = CollisionShape2D.new()
	cs_loot_area.name = "AttackAreaCollisionShape2D"
	loot_area.add_child(cs_loot_area)

	var cs_loot_area_circle = CircleShape2D.new()

	cs_loot_area_circle.radius = stats_component.loot_range
	cs_loot_area.shape = cs_loot_area_circle

	add_child(loot_area)

	loot_area.body_entered.connect(_on_loot_area_entered)
	loot_area.body_exited.connect(_on_loot_area_exited)


func _init_interact_area():
	var interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 0
	interact_area.collision_mask = J.PHYSICS_LAYER_NPCS

	var cs_interact_area = CollisionShape2D.new()
	cs_interact_area.name = "AttackAreaCollisionShape2D"
	interact_area.add_child(cs_interact_area)

	var cs_interact_area_circle = CircleShape2D.new()

	cs_interact_area_circle.radius = stats_component.loot_range
	cs_interact_area.shape = cs_interact_area_circle

	add_child(interact_area)

	interact_area.body_entered.connect(_on_interact_area_npc_entered)
	interact_area.body_exited.connect(_on_interact_area_npc_exited)


func _physics_process(delta: float):
	if J.is_server():
		behavior(delta)

	if not stats_component.is_dead:
		target_node.move_and_slide()


func behavior(_delta: float):
	if stats_component.is_dead:
		target_node.velocity = Vector2.ZERO
		moving = false
		interacting = false
		interact_target = null
	elif moving:
		if target_node.position.distance_to(move_target) > J.ARRIVAL_DISTANCE:
			target_node.velocity = (
				target_node.position.direction_to(move_target) * stats_component.movement_speed
			)
		else:
			moving = false
			target_node.velocity = Vector2.ZERO
	elif interacting:
		if not is_instance_valid(interact_target):
			interacting = false
			interact_target = null
			return

		match interact_type:
			INTERACT_TYPE.ENEMY:
				if interact_target.stats.is_dead:
					interacting = false
					interact_target = null
				elif not enemies_in_attack_range.has(interact_target):
					target_node.velocity = (
						target_node.position.direction_to(interact_target.position)
						* stats_component.movement_speed
					)
				else:
					target_node.velocity = Vector2.ZERO

					if attack_timer.is_stopped():
						attack(interact_target)
						attack_timer.start(stats_component.attack_speed)

			INTERACT_TYPE.NPC:
				if not npcs_in_interact_range.has(interact_target):
					target_node.velocity = (
						target_node.position.direction_to(interact_target.position)
						* stats_component.movement_speed
					)
				else:
					target_node.velocity = Vector2.ZERO
					interact_target.interact(target_node)
					interacting = false
					interact_target = null
			INTERACT_TYPE.ITEM:
				if not items_in_loot_range.has(interact_target):
					target_node.velocity = (
						target_node.position.direction_to(interact_target.position)
						* stats_component.movement_speed
					)
				else:
					target_node.velocity = Vector2.ZERO
					interact_target.loot(target_node)
					interacting = false
					interact_target = null


func attack(target: CharacterBody2D):
	var damage = randi_range(stats_component.attack_power_min, stats_component.attack_power_max)

	if target.get("stats"):
		target.stats.hurt(target_node, damage)
		if action_synchronizer:
			action_synchronizer.attack(target_node.name, damage)


func _on_attack_area_enemy_entered(body: Node2D):
	if not body.get("enemy_class"):
		J.logger.warn("Body is not an Enemy")
		return

	if not enemies_in_attack_range.has(body):
		enemies_in_attack_range.append(body)


func _on_attack_area_enemy_exited(body: Node2D):
	if enemies_in_attack_range.has(body):
		enemies_in_attack_range.erase(body)


func _on_loot_area_entered(body: Node2D):
	if not body.get("item_class"):
		J.logger.warn("Body is not an Item")
		return

	if not items_in_loot_range.has(body):
		items_in_loot_range.append(body)


func _on_loot_area_exited(body: Node2D):
	if items_in_loot_range.has(body):
		items_in_loot_range.erase(body)


func _on_interact_area_npc_entered(body: Node2D):
	if not body.get("npc_class"):
		J.logger.warn("Body is not an NPC")
		return

	if not npcs_in_interact_range.has(body):
		npcs_in_interact_range.append(body)


func _on_interact_area_npc_exited(body: Node2D):
	if npcs_in_interact_range.has(body):
		npcs_in_interact_range.erase(body)


func _on_moved(target_position: Vector2):
	interacting = false

	moving = true
	move_target = target_position


func _on_interacted(target_name: String):
	moving = false

	if J.world.enemies.has_node(target_name):
		interacting = true
		interact_target = J.world.enemies.get_node(target_name)
		interact_type = INTERACT_TYPE.ENEMY
		return

	if J.world.npcs.has_node(target_name):
		interacting = true
		interact_target = J.world.npcs.get_node(target_name)
		interact_type = INTERACT_TYPE.NPC
		return

	if J.world.items.has_node(target_name):
		interacting = true
		interact_target = J.world.items.get_node(target_name)
		interact_type = INTERACT_TYPE.ITEM
		return


func _on_attack_timer_timeout():
	attack_timer.stop()
