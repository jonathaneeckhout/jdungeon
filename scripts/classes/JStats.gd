extends Node

class_name JStats

signal loaded
signal synced

const EXPERIENCE_PER_LEVEL_BASE:float = 100

const Keys:Dictionary = {
	HP="hp",
	HP_MAX="hp_max",
	DEFENSE="defense",
	RESISTANCE="resistance",
	STRENGTH="attribute_strength",
	DEXTERITY="attribute_dexterity",
	MIND="attribute_mind",
	EVASION="evasion",
	ACCURACY="accuracy",
	EXPERIENCE="experience",
	LEVEL="level"
	
}

#Stats which depend on other stats should not be directly set
#Use their update_ method instead
const READ_ONLY_KEYS:Array[String] = [Keys.HP_MAX, Keys.EVASION]

@export var parent: JBody2D

var hp_max: int = 10:
	set(new_hp_max):
		hp_max = clamp(new_hp_max, 0, INF)
		#Update hp clamping
		hp = hp
		
var hp: int = hp_max:
	set(new_hp):
		hp = clamp(new_hp, -INF, hp_max)
		
var attribute_strength: float
var attribute_dexterity: float
var attribute_mind: float
		
var evasion:float
var accuracy:float
		
var attack_power_min: int = 0
var attack_power_max: int = 10
var attack_speed: float = 0.8
var attack_range: float = 64.0
var defense: float = 0

var movement_speed: float = 300.0

var level: int = 1:
	set(newLevel):
		level = newLevel
		
var experience: float = 0

var experience_worth: float

#Dictionary of stat "Keys" that holds an Array[JStatBoost] (not typed)
var statToBoostDict:Dictionary #Format: String:Array[JStatBoost]

#Dictionary of JStatBoost.stackSource that holds Array[JStatBoost] (not typed)
var stackSourceToBoostDict:Dictionary #Format: String:Array[JStatBoost]

func _init() -> void:
	assert(statToBoostDict.is_empty())
	for key in Keys.values():
		statToBoostDict[key] = []

func stat_get(statKey:String)->float:
	assert(statKey in Keys.values())
	return get(statKey)

func stat_set(statKey:String, value:float):
	set(statKey, value)

#Used as a shortcut to check if a given stat can be modified directly
func stat_is_read_only(statkey:String)->bool:
	return statkey in READ_ONLY_KEYS

#Takes in a value and returns its value boosted by all the matching JStatBoosts
func stat_get_boosted(statKey:String, statValue:float)->float:
	stat_boost_clean_array(statToBoostDict[statKey])
	
	var multiplier: float
	var additive: float
	var total: float = statValue
	
	for boost in statToBoostDict.get(statKey, []):
		if boost is JStatBoost:
			match boost.type:
				JStatBoost.Types.ADDITIVE:
					additive += boost.value
				JStatBoost.Types.MULTIPLICATIVE:
					multiplier *= boost.value

	return (total + additive) * multiplier

#Stat boosts that come from the same source cannot stack, the most powerful is chosen instead
func stat_boost_add(statBoost:JStatBoost):
	assert(statBoost.statKey in Keys.values(), "This statBoost has a key that doesn't exist.")
	
	
	statToBoostDict[statBoost.statKey].append(statBoost)
	stackSourceToBoostDict[statBoost.stackSource].append(statBoost)

func stat_boost_remove_(statBoost:JStatBoost):
	assert(statBoost.statKey in Keys.values(), "This statBoost has a key that doesn't exist.")
	
	statToBoostDict[statBoost.statKey].erase(statBoost)
	stackSourceToBoostDict[statBoost.stackSource].erase(statBoost)

func stat_boost_get_stacks_from_source(stackSource:String)->int:
	stat_boost_clean_array(stackSourceToBoostDict[stackSource])
	return stackSourceToBoostDict[stackSource].size()
		
func stat_boost_clean_array(array:Array):
	array = array.filter( func(obj:Object):
		return is_instance_valid(obj)
	)

func stat_boost_create(key:String, amount:float, source:String = "", stackLimit:int = 0):
	var boost:=JStatBoost.new()
	boost.source = source
	boost.statKey = key
	boost.amount = amount
	return boost

func stat_update_all():
	hp_max_update()
	evasion_update()
	level_update()
	pass

func hp_hurt(damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - defense)

	# # Deal damage if hp pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0

	return reduced_damage


func hp_heal(healing: int) -> int:
	hp = min(hp_max, hp + healing)

	return healing


func hp_reset():
	hp = hp_max

func hp_max_update():
	#Base 100 hp_max
	#Plus 20 hp_max per level
	#Finally using strength as a modifier (10 strength = 10% more HP)
	var hpMax:float = (100 + level * 20) * (1 + attribute_strength / 100)
	hp_max = stat_get_boosted(Keys.HP_MAX, hpMax)

func accuracy_update():
	accuracy = stat_get_boosted(Keys.ACCURACY, 100)

func evasion_update():
	evasion = stat_get_boosted(Keys.EVASION, 1)


func to_json() -> Dictionary:
	return {"hp_max": hp_max, "hp": hp, "level": level, "experience": experience}


func from_json(data: Dictionary) -> bool:
	if "hp_max" not in data:
		J.logger.warn('Failed to load stats from data, missing "hp_max" key')
		return false

	if "hp" not in data:
		J.logger.warn('Failed to load stats from data, missing "hp" key')
		return false
	if "level" not in data:
		J.logger.warn('Failed to load stats from data, missing "level" key')
		return false

	if "experience" not in data:
		J.logger.warn('Failed to load stats from data, missing "experience" key')
		return false

	hp_max = data["hp_max"]
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	# levelUpExperienceRequired = calculate_experience_needed(level)

	loaded.emit()

	return true


#Level is based on the amount of experience the character has
func level_get_from_experience()->float:
	return experience / 100

func level_get_experience_to_next()->float:
	return fmod(experience, 100)

func level_update():
	var originalLevel:int = level
	level = level_get_from_experience()
	
	if originalLevel != level:
		parent.synchronizer.sync_level( level, level - originalLevel, level_get_experience_to_next() )

func experience_add(from: String, amount: int):
	experience += amount

	level_update()
	parent.synchronizer.sync_experience(from, experience, amount)


@rpc("call_remote", "any_peer", "reliable") func get_sync(id: int):
	if not J.is_server():
		return

	if id in multiplayer.get_peers():
		sync.rpc_id(id, to_json())


@rpc("call_remote", "authority", "unreliable") func sync(data: Dictionary):
	hp_max = data["hp_max"]
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	synced.emit()


class JStatBoost extends RefCounted:
	enum Types {ADDITIVE, MULTIPLICATIVE}
	
	var type:Types
	
	#The source is used to define if this boost can be stacked or not
	#Boosts from different sources do not contribute to the same stack
	var stackSource:String = ""
	
	#How many can be stacked, anything lower than 0 means it is infinite
	var stackLimit:int = 1
	
	var statKey:String
	
	var value:float
	
	#May be used to indirectly remove this boost
	var freeSignal:Signal:
		set(val):
			freeSignal = val
			freeSignal.connect(free)
	
	
	
