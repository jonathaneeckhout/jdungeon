extends Node

enum MODE { SERVER, CLIENT }
enum ENTITY_TYPE { PLAYER, ENEMY, ITEM, NPC }

const PHYSICS_LAYER_WORLD = 1
const PHYSICS_LAYER_PLAYERS = 2
const PHYSICS_LAYER_ENEMIES = 4
const PHYSICS_LAYER_NPCS = 8
const PHYSICS_LAYER_ITEMS = 16
const PHYSICS_LAYER_NETWORKING = 32

const ARRIVAL_DISTANCE = 8
const DROP_RANGE = 64

const PERSISTENCY_INTERVAL = 60.0
const PLAYER_RESPAWN_TIME = 10.0

var player_scene: Resource
var enemy_scenes: Dictionary = {}
var npc_scenes: Dictionary = {}
var item_scenes: Dictionary = {}
var skill_resources: Dictionary = {}
var map_scenes: Dictionary = {}

var uuid_util: UuidUtil

var audio: SoundManager = SoundManager.new()


func _ready():
	uuid_util = load("res://scripts/uuid/uuid.gd").new()


func register_scenes():
	J.register_player_scene("res://scenes/player/Player.tscn")

	register_enemies()
	register_npcs()
	register_items()
	register_skills()
	register_maps()


func register_enemies():
	J.register_enemy_scene("Sheep", "res://scenes/enemies/Sheep/Sheep.tscn")
	J.register_enemy_scene("TreeTrunkGuy", "res://scenes/enemies/TreeTrunkGuy/TreeTrunkGuy.tscn")
	J.register_enemy_scene("MoldedDruvar", "res://scenes/enemies/MoldedDruvar/MoldedDruvar.tscn")
	J.register_enemy_scene("ClamDog", "res://scenes/enemies/ClamDog/ClamDog.tscn")


func register_npcs():
	J.register_npc_scene("MilkLady", "res://scenes/npcs/milklady/Milklady.tscn")
	J.register_npc_scene("Turtur", "res://scenes/npcs/turtur/Turtur.tscn")


func register_items():
	J.register_item_scene("Gold", "res://scenes/items/varia/gold/Gold.tscn")

	J.register_item_scene(
		"HealthPotion", "res://scenes/items/consumables/healthpotion/HealthPotion.tscn"
	)

	J.register_item_scene("Axe", "res://scenes/items/equipment/weapons/axe/Axe.tscn")
	J.register_item_scene("Sword", "res://scenes/items/equipment/weapons/sword/Sword.tscn")
	J.register_item_scene("Club", "res://scenes/items/equipment/weapons/club/Club.tscn")

	J.register_item_scene(
		"IronShield", "res://scenes/items/equipment/weapons/ironshield/IronShield.tscn"
	)

	J.register_item_scene(
		"LeatherHelm", "res://scenes/items/equipment/armour/leatherhelm/LeatherHelm.tscn"
	)
	J.register_item_scene(
		"LeatherBody", "res://scenes/items/equipment/armour/leatherbody/LeatherBody.tscn"
	)
	J.register_item_scene(
		"LeatherArms", "res://scenes/items/equipment/armour/leatherarms/LeatherArms.tscn"
	)
	J.register_item_scene(
		"LeatherLegs", "res://scenes/items/equipment/armour/leatherlegs/LeatherLegs.tscn"
	)

	J.register_item_scene(
		"ChainMailHelm", "res://scenes/items/equipment/armour/chainmailhelm/ChainMailHelm.tscn"
	)
	J.register_item_scene(
		"ChainMailBody", "res://scenes/items/equipment/armour/chainmailbody/ChainMailBody.tscn"
	)
	J.register_item_scene(
		"ChainMailArms", "res://scenes/items/equipment/armour/chainmailarms/ChainMailArms.tscn"
	)
	J.register_item_scene(
		"ChainMailLegs", "res://scenes/items/equipment/armour/chainmaillegs/ChainMailLegs.tscn"
	)

	J.register_item_scene(
		"PlateHelm", "res://scenes/items/equipment/armour/platehelm/PlateHelm.tscn"
	)
	J.register_item_scene(
		"PlateBody", "res://scenes/items/equipment/armour/platebody/PlateBody.tscn"
	)
	J.register_item_scene(
		"PlateArms", "res://scenes/items/equipment/armour/platearms/PlateArms.tscn"
	)
	J.register_item_scene(
		"PlateLegs", "res://scenes/items/equipment/armour/platelegs/PlateLegs.tscn"
	)


func register_skills():
	J.register_skill_resource("debug", "res://scripts/components/skillcomponent/Skills/debug.tres")
	J.register_skill_resource(
		"HealSelf", "res://scripts/components/skillcomponent/Skills/HealSelf.tres"
	)
	J.register_skill_resource(
		"Combustion", "res://scripts/components/skillcomponent/Skills/Combustion.tres"
	)


func register_maps():
	J.register_map_scene("World", "res://scenes/maps/world/World.tscn")
	J.register_map_scene("BaseCamp", "res://scenes/maps/basecamp/BaseCamp.tscn")
	J.register_map_scene("WakeningForest", "res://scenes/maps/wakeningforest/WakeningForest.tscn")
	J.register_map_scene("ForestDungeon", "res://scenes/maps/forestdungeon/ForestDungeon.tscn")


func register_player_scene(player_scene_path: String):
	player_scene = load(player_scene_path)


func register_enemy_scene(enemy_class: String, enemy_scene_path: String):
	enemy_scenes[enemy_class] = load(enemy_scene_path)


func register_npc_scene(npc_class: String, npc_scene_path: String):
	npc_scenes[npc_class] = load(npc_scene_path)


func register_item_scene(item_class: String, item_scene_path: String):
	item_scenes[item_class] = load(item_scene_path)


func register_map_scene(map_name: String, map_scene_path: String):
	map_scenes[map_name] = load(map_scene_path)


func register_skill_resource(skill_class: String, skill_res_path: String):
	skill_resources[skill_class] = load(skill_res_path)
	assert(skill_class == skill_resources[skill_class].skill_class)
