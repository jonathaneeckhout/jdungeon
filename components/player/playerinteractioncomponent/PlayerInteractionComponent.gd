extends Node2D

class_name PlayerInteractionComponent

@export var player_synchronizer: PlayerSynchronizer

@export var attack_radius: float = 32.0
@export var attack_range: int = 48
@export var loot_range: int = 128.0
@export var npc_interact_range: int = 128.0

var target_node: Node

var attack_area: Area2D
var loot_area: Area2D
var interact_area: Area2D

var enemies_in_attack_range: Array[Enemy] = []
var items_in_loot_range: Array[Item] = []
var npcs_in_interact_range: Array[NPC] = []

@onready var crosshair: Sprite2D = $Crosshair


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.multiplayer_connection.is_server():
		_init_loot_area()
		_init_npc_interact_area()
		set_physics_process(false)
	elif not target_node.multiplayer_connection.is_own_player(target_node):
		queue_free()
	else:
		_init_attack_area()


func _physics_process(_delta):
	attack_area.position = (
		target_node.position.direction_to(player_synchronizer.mouse_global_pos) * attack_range
	)

	crosshair.position = attack_area.position


func _init_attack_area():
	attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0
	attack_area.collision_mask = J.PHYSICS_LAYER_ENEMIES

	var cs_attack_area = CollisionShape2D.new()
	cs_attack_area.name = "AttackAreaCollisionShape2D"
	attack_area.add_child(cs_attack_area)

	var cs_attack_area_circle = CircleShape2D.new()

	cs_attack_area_circle.radius = attack_radius
	cs_attack_area.shape = cs_attack_area_circle

	add_child(attack_area)

	attack_area.area_entered.connect(_on_attack_area_enemy_entered)
	attack_area.area_exited.connect(_on_attack_area_enemy_exited)


func _init_loot_area():
	loot_area = Area2D.new()
	loot_area.name = "LootArea"
	loot_area.collision_layer = 0
	loot_area.collision_mask = J.PHYSICS_LAYER_ITEMS

	var cs_loot_area = CollisionShape2D.new()
	cs_loot_area.name = "LootAreaCollisionShape2D"
	loot_area.add_child(cs_loot_area)

	var cs_loot_area_circle = CircleShape2D.new()

	cs_loot_area_circle.radius = loot_range
	cs_loot_area.shape = cs_loot_area_circle

	add_child(loot_area)

	loot_area.body_entered.connect(_on_loot_area_entered)
	loot_area.body_exited.connect(_on_loot_area_exited)


func _init_npc_interact_area():
	interact_area = Area2D.new()
	interact_area.name = "NPCInteractArea"
	interact_area.collision_layer = 0
	interact_area.collision_mask = J.PHYSICS_LAYER_NPCS

	var cs_interact_area = CollisionShape2D.new()
	cs_interact_area.name = "NPCInteractAreaCollisionShape2D"
	interact_area.add_child(cs_interact_area)

	var cs_interact_area_circle = CircleShape2D.new()

	cs_interact_area_circle.radius = npc_interact_range
	cs_interact_area.shape = cs_interact_area_circle

	add_child(interact_area)

	interact_area.area_entered.connect(_on_interact_area_npc_entered)
	interact_area.area_exited.connect(_on_interact_area_npc_exited)


func _on_attack_area_enemy_entered(area: Area2D):
	var enemy: Enemy = area.get_parent()

	if not enemies_in_attack_range.has(enemy):
		enemies_in_attack_range.append(enemy)


func _on_attack_area_enemy_exited(area: Area2D):
	var enemy: Enemy = area.get_parent()

	if enemies_in_attack_range.has(enemy):
		enemies_in_attack_range.erase(enemy)


func _on_loot_area_entered(body: Node2D):
	if not body.get("item_class"):
		GodotLogger.warn("Body is not an Item")
		return

	if not items_in_loot_range.has(body):
		items_in_loot_range.append(body)


func _on_loot_area_exited(body: Node2D):
	if items_in_loot_range.has(body):
		items_in_loot_range.erase(body)


func _on_interact_area_npc_entered(area: Area2D):
	var npc: NPC = area.get_parent()

	if not npcs_in_interact_range.has(npc):
		npcs_in_interact_range.append(npc)


func _on_interact_area_npc_exited(area: Area2D):
	var npc: NPC = area.get_parent()

	if npcs_in_interact_range.has(npc):
		npcs_in_interact_range.erase(npc)
