extends Node

class_name JStats

signal loaded
signal synced

signal stat_changed(statName:String)

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
const READ_ONLY_KEYS:Array[String] = [Keys.HP_MAX, Keys.EVASION, Keys.ACCURACY, Keys.LEVEL]

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

var defense: float = 0
var resistance: float = 0:
	set(val):
		resistance = clamp(val, 0, 100)

#Movement speed should PROBABLY remain unaffected as much as possible
var movement_speed: float = 300.0
		
#What do i do with these?
var attack_power_min: int = 0
var attack_power_max: int = 10
var attack_speed: float = 0.8
var attack_range: float = 64.0


var level: int
		
var experience: float = 0

var experience_worth: float

#Dictionary of stat "Keys" that holds an Array[Boost] (not typed)
var statToBoostDict:Dictionary #Format: String:Array[Boost]

#Dictionary of Boost.stackSource that holds Array[Boost] (not typed)
var stackSourceToBoostDict:Dictionary #Format: String:Array[Boost]

func _init() -> void:
	assert(statToBoostDict.is_empty())
	for key in Keys.values():
		statToBoostDict[key] = []

func stat_get(statKey:String)->float:
	assert(statKey in Keys.values())
	
	#Auto update relevant stats when they are retrieved
	if statKey in READ_ONLY_KEYS:
		assert(has_method(&"update_" + statKey), "There is no method for updating this read-only stat.")
		Callable(self, &"update_" + statKey).call()
	
	return stat_get_boosted(statKey, get(statKey))

#Returns the stat without boosts
func stat_get_raw(statKey:String)->float:
	if statKey in READ_ONLY_KEYS:
		assert(has_method(&"update_" + statKey), "There is no method for updating this read-only stat.")
		Callable(self, &"update_" + statKey).call()
	
	return get(statKey)

func stat_set(statKey:String, value:float):
	if statKey in READ_ONLY_KEYS:
		push_warning("Stats of this type should not be set directly.")
		
	set(statKey, value)
	
	stat_changed.emit(statKey)

#Used as a shortcut to check if a given stat can be modified directly
func stat_is_read_only(statkey:String)->bool:
	return statkey in READ_ONLY_KEYS

#Takes in a value and returns it boosted by all the matching Boosts for the given stat
func stat_get_boosted(statKey:String, statValue:float)->float:
	stat_boost_clean_array(statToBoostDict[statKey])
	
	var multiplier: float = 1
	var additive: float = 0
	var total: float = statValue
	
	for boost in statToBoostDict.get(statKey, []):
		if boost is Boost:
			match boost.type:
				Boost.Types.ADDITIVE:
					additive += boost.value
				Boost.Types.MULTIPLICATIVE:
					multiplier *= boost.value

	return (total + additive) * multiplier

#Stat boosts that come from the same source cannot stack
func stat_boost_add(statBoost:Boost):
	assert(statBoost.statKey in Keys.values(), "This statBoost has a key that doesn't exist.")
	var wasAdded: bool
	
	#Abort if the stack limit is not infinite and it would exceed the boosts from the current source
	if statBoost.stackLimit > 0 and stat_boost_get_stacks_from_source(statBoost.stackSource) > statBoost.stackLimit:
		return
	
	#Only add it if it is not already in the dicts
	if not statToBoostDict[statBoost.statKey].has(statBoost):
		statToBoostDict[statBoost.statKey].append(statBoost)
		wasAdded = true
	
	#Add this source to the dict if not present
	if not stackSourceToBoostDict.has(statBoost.stackSource):
		stackSourceToBoostDict[statBoost.stackSource] = []
	
	#Add this item to the source dictionary if not present
	if not stackSourceToBoostDict[statBoost.stackSource].has(statBoost):
		stackSourceToBoostDict[statBoost.stackSource].append(statBoost)
		
	#The signal should be emitted last to ensure the boost has been properly registered before anything else tries to touch it
	if wasAdded:
		stat_changed.emit(statBoost.statKey)

func stat_boost_remove_(statBoost:Boost):
	assert(statBoost.statKey in Keys.values(), "This statBoost has a key that doesn't exist.")
	
	statToBoostDict[statBoost.statKey].erase(statBoost)
	stackSourceToBoostDict[statBoost.stackSource].erase(statBoost)

func stat_boost_get_stacks_from_source(stackSource:String)->int:
	stat_boost_clean_array(stackSourceToBoostDict.get(stackSource, []))
	return stackSourceToBoostDict.get(stackSource, []).size()
		
func stat_boost_clean_array(array:Array):
	array = array.filter( func(obj:Object):
		return is_instance_valid(obj)
	)

func stat_boost_create(key:String, amount:float, source:String = "", stackLimit:int = 0)->Boost:
	var boost:=Boost.new()
	boost.source = source
	boost.statKey = key
	boost.amount = amount
	boost.stackLimit = stackLimit
	return boost

func update_all_stats():
	update_hp_max()
	update_evasion()
	update_level()
	pass

func hp_hurt(damage: float) -> float:
	#Reduce the damage according to the defense stat
	var reduced_damage: float = max(0, damage - defense)
	
	var resistance_modifier: float = 1 - (resistance / 100)
	var resisted_damage: float = max(0, reduced_damage * resistance_modifier)

	#Apply the reduction
	hp = clamp(hp - resisted_damage, 0, hp_max)

	return resisted_damage


func hp_heal(healing: float) -> float:
	hp = min(hp_max, hp + healing)

	return healing


func hp_reset():
	hp = hp_max

#Do NOT use stat_set in update methods, otherwise it will cause an infinite recursion.
func update_hp_max():
	#Base 100 hp_max
	#Plus 20 hp_max per level
	#Finally using strength as a modifier (10 strength = 10% more HP)
	var hpMax:float = (100 + level * 20) * (1 + attribute_strength / 100)
	hp_max = stat_get_boosted(Keys.HP_MAX, hpMax)

func update_accuracy():
	accuracy = stat_get_boosted(Keys.ACCURACY, 100)

func update_evasion():
	evasion = stat_get_boosted(Keys.EVASION, 0)

func update_level():
	level = level_get_from_experience()
	
#Level is based on the amount of experience the character has
func level_get_from_experience()->float:
	return 1 + (experience / 100)

func level_get_experience_to_next()->float:
	return fmod(experience, 100)


func experience_add(from: String, amount: int):
	experience += amount

	update_level()
	parent.synchronizer.sync_experience(from, experience, amount)

func to_json() -> Dictionary:
	update_all_stats()
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

	loaded.emit()

	return true

#Used by the server to sync all stats on clients (UNUSED???)
@rpc("call_remote", "any_peer", "reliable") func get_sync(id: int):
	if not J.is_server():
		return
	
	update_all_stats()

@rpc("call_remote", "any_peer", "reliable") func sync_stats(id: int):
	if not J.is_server():
		return

	var caller_id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(caller_id):
		return

	if id in multiplayer.get_peers():
		sync_response.rpc_id(id, to_json())



@rpc("call_remote", "authority", "unreliable") func sync_response(data: Dictionary):
	hp_max = data["hp_max"]

	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	synced.emit()


class Boost extends RefCounted:
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
			freeSignal.connect(self.free)
	
	
	
