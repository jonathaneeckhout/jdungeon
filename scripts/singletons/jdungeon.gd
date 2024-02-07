extends Node

enum MODE { SERVER, CLIENT }
enum ENTITY_TYPE { PLAYER, ENEMY, ITEM, NPC }

const PHYSICS_LAYER_WORLD = 1
const PHYSICS_LAYER_PLAYERS = 2
const PHYSICS_LAYER_ENEMIES = 4
const PHYSICS_LAYER_NPCS = 8
const PHYSICS_LAYER_ITEMS = 16
const PHYSICS_LAYER_NETWORKING = 32
const PHYSICS_LAYER_PROJECTILE = 64
const PHYSICS_LAYER_PASSABLE_ENTITIES = 128

const ARRIVAL_DISTANCE = 8
const DROP_RANGE = 64

const PERSISTENCY_INTERVAL = 60.0
const PLAYER_RESPAWN_TIME = 10.0

var player_scene: Resource
var enemy_scenes: Dictionary = {}
var npc_scenes: Dictionary = {}
var item_scenes: Dictionary = {}
var map_scenes: Dictionary = {}
var projectile_scenes: Dictionary = {}
var skill_resources: Dictionary = {}
var charclass_resources: Dictionary = {}
var dialogue_resources: Dictionary = {}
var status_effect_resources: Dictionary = {}

var uuid_util: UuidUtil

var audio: SoundManager = SoundManager.new()

var server_client_multiplayer_connection: WebsocketMultiplayerConnection = null


func _ready():
	uuid_util = load("res://scripts/utilities/uuid/uuid.gd").new()

	audio.player_parent = self
	audio.main_instance = audio


func register_scenes():
	J.register_player_scene("res://scenes/player/Player.tscn")

	register_enemies()
	register_npcs()
	register_items()
	# register_skills()
	register_maps()
	# register_projectiles()
	# register_character_classes()
	# register_dialogues()
	# register_status_effects()


func register_enemies():
	J.register_enemy_scene("Sheep", "res://scenes/enemies/Sheep/Sheep.tscn")
	# J.register_enemy_scene("TreeTrunkGuy", "res://scenes/enemies/TreeTrunkGuy/TreeTrunkGuy.tscn")
	# J.register_enemy_scene("MoldedDruvar", "res://scenes/enemies/MoldedDruvar/MoldedDruvar.tscn")
	# J.register_enemy_scene("ClamDog", "res://scenes/enemies/ClamDog/ClamDog.tscn")
	J.register_enemy_scene("BlueMole", "res://scenes/enemies/BlueMole/BlueMole.tscn")
	J.register_enemy_scene("WildBoar", "res://scenes/enemies/WildBoar/WildBoar.tscn")
	J.register_enemy_scene("Ladybug", "res://scenes/enemies/Ladybug/Ladybug.tscn")


func register_npcs():
	J.register_npc_scene("MilkLady", "res://scenes/npcs/milklady/Milklady.tscn")
	J.register_npc_scene("Turtur", "res://scenes/npcs/turtur/Turtur.tscn")
	# J.register_npc_scene("Fernand", "res://scenes/npcs/fernand/Fernand.tscn")
	J.register_npc_scene("Guard", "res://scenes/npcs/guard/Guard.tscn")


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


# func register_skills():
# 	J.register_skill_resource(
# 		"debug", "res://scripts/components/player/skillcomponent/Skills/debug.tres"
# 	)
# 	J.register_skill_resource(
# 		"HealSelf", "res://scripts/components/player/skillcomponent/Skills/HealSelf.tres"
# 	)
# 	J.register_skill_resource(
# 		"Combustion", "res://scripts/components/player/skillcomponent/Skills/Combustion.tres"
# 	)
# 	J.register_skill_resource(
# 		"PoisonSelf", "res://scripts/components/player/skillcomponent/Skills/DebugPoisonSelf.tres"
# 	)
# 	J.register_skill_resource(
# 		"SpinAttack", "res://scripts/components/player/skillcomponent/Skills/SpinAttack.tres"
# 	)
# 	J.register_skill_resource(
# 		"Cripple", "res://scripts/components/player/skillcomponent/Skills/Cripple.tres"
# 	)
# 	J.register_skill_resource(
# 		"Defend", "res://scripts/components/player/skillcomponent/Skills/Defend.tres"
# 	)
# 	J.register_skill_resource(
# 		"BasicAttack", "res://scripts/components/player/skillcomponent/Skills/BasicAttack.tres"
# 	)
# 	J.register_skill_resource(
# 		"LaunchArrow", "res://scripts/components/player/skillcomponent/Skills/LaunchArrow.tres"
# 	)
# 	J.register_skill_resource(
# 		"SetTrap", "res://scripts/components/player/skillcomponent/Skills/SetTrap.tres"
# 	)


func register_maps():
	# J.register_map_scene("World", "res://scenes/maps/world/World.tscn")
	J.register_map_scene("BaseCamp", "res://scenes/maps/basecamp/BaseCamp.tscn")
	# J.register_map_scene("WakeningForest", "res://scenes/maps/wakeningforest/WakeningForest.tscn")
	# J.register_map_scene("ForestDungeon", "res://scenes/maps/forestdungeon/ForestDungeon.tscn")


# func register_character_classes():
# 	J.register_class_resource(
# 		"Base", "res://scripts/components/player/charclasscomponent/classes/Base.tres"
# 	)
# 	J.register_class_resource(
# 		"Warrior", "res://scripts/components/player/charclasscomponent/classes/Warrior.tres"
# 	)
# 	J.register_class_resource(
# 		"Hexpecialist",
# 		"res://scripts/components/player/charclasscomponent/classes/Hexpecialist.tres"
# 	)
# 	J.register_class_resource(
# 		"Ranger", "res://scripts/components/player/charclasscomponent/classes/Ranger.tres"
# 	)

# func register_dialogues():
# 	J.register_dialogue_resource("MilkLady", "res://scenes/ui/dialogue/Dialogues/MilkLady.tres")
# 	J.register_dialogue_resource("Fernand", "res://scenes/ui/dialogue/Dialogues/Fernand.tres")
# 	J.register_dialogue_resource("FALLBACK", "res://scenes/ui/dialogue/Dialogues/FALLBACK.tres")

# func register_status_effects():
# 	J.register_status_effect_resource(
# 		"Poison",
# 		"res://scripts/components/networking/statuseffectcomponent/StatusEffects/Poison.tres"
# 	)
# 	(
# 		J
# 		. register_status_effect_resource(
# 			"DefenseUpPerStackFlat",
# 			"res://scripts/components/networking/statuseffectcomponent/StatusEffects/DefenseUpStatChange.tres"
# 		)
# 	)
# 	(
# 		J
# 		. register_status_effect_resource(
# 			"DefenseDownPerStackFlat",
# 			"res://scripts/components/networking/statuseffectcomponent/StatusEffects/DefenseDownPerStackFlat.tres"
# 		)
# 	)
# 	(
# 		J
# 		. register_status_effect_resource(
# 			"AttackDownPerStackFlat",
# 			"res://scripts/components/networking/statuseffectcomponent/StatusEffects/AttackDownPerStackFlat.tres"
# 		)
# 	)

# func register_projectiles():
# 	J.register_projectile_scene(
# 		"Arrow",
# 		"res://scripts/components/networking/projectilesynchronizercomponent/Projectiles/Arrow.tscn"
# 	)
# 	J.register_projectile_scene(
# 		"Trap",
# 		"res://scripts/components/networking/projectilesynchronizercomponent/Projectiles/Trap.tscn"
# 	)


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


func register_class_resource(charclass_class: String, class_res_path: String):
	charclass_resources[charclass_class] = load(class_res_path)
	assert(charclass_class == charclass_resources[charclass_class].class_registered)


func register_dialogue_resource(dialogue_class: String, dialogue_res_path: String):
	dialogue_resources[dialogue_class] = load(dialogue_res_path)
	assert(dialogue_class == dialogue_resources[dialogue_class].dialogue_identifier)


func register_status_effect_resource(status_class: String, status_res_path: String):
	status_effect_resources[status_class] = load(status_res_path)
	assert(status_class == status_effect_resources[status_class].status_class)


func register_projectile_scene(projectile_class: String, projectile_scene_path: String):
	projectile_scenes[projectile_class] = load(projectile_scene_path)
