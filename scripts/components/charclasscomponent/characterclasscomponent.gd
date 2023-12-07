extends Node
class_name CharacterClassComponent

const JSON_KEYS: Array[String] = ["classes", "class_whitelist", "class_blacklist", "max_classes"]

signal classes_changed
signal list_changed

@export var user: Node

@export var stats_component: StatsSynchronizerComponent

var classes: Array[CharacterClassResource]

##Only those here will be presented to the user, leave empty to disable
var class_whitelist: Array[String]

##Removes any option presented to the user that's defined here, taking precedence over [member class_whitelist]
var class_blacklist: Array[String]

var max_classes: int = 2


func _ready():
	if user.get("component_list") != null:
		user.component_list["class_component"] = self
	
	if G.is_server():
		return

	#Wait until the connection is ready to synchronize stats
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server

	#Wait an additional frame so others can get set.
	await get_tree().process_frame

	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered
	
	#TEMP?
	add_class("Base")
	G.sync_rpc.characterclasscomponent_sync_all.rpc_id(1, user.get_name())

func set_blacklist(charclass: String, enabled: bool):
	if enabled and not charclass in class_blacklist:
		class_blacklist.append(charclass)
	elif not enabled:
		class_blacklist.erase(charclass)
	list_changed.emit()


func set_whitelist(charclass: String, enabled: bool):
	if enabled and not charclass in class_blacklist:
		class_whitelist.append(charclass)
	elif not enabled:
		class_whitelist.erase(charclass)
	list_changed.emit()
		

func remove_class(charclass: String):
	if classes.is_empty():
		GodotLogger.warn("Tried to remove a class but there are none in this component.")
		return
		
	# Clean the classes Array of any class matching this charclass
	var index: int = 0
	while index < classes.size():
		if classes[index].class_registered == charclass:
			classes.remove_at(index)
			classes_changed.emit()
			return
	


func add_class(charclass: String, bypassLimit: bool = false):
	if bypassLimit or classes.size() >= max_classes:
		GodotLogger.warn("Tried to add a class but the limit has already been reached for this component.")
		return
	
	if charclass in class_blacklist:
		GodotLogger.warn("Added a blacklisted class '{0}'.".format([charclass]))
	
	if not class_whitelist.is_empty() and not charclass in class_whitelist:
		GodotLogger.warn("Whitelist is enabled (not empty) but class '{0}' isn't in it.".format([charclass]))
		
		
	var charClass: CharacterClassResource = J.charclass_resources[charclass].duplicate()
	classes.append(charClass)
	classes_changed.emit()


## Applies bonuses and multipliers to the character's StatsSynchronizerComponent
func apply_stats():
	
	#If the stats are not ready, wait another frame.
	if not stats_component.ready_done:
		get_tree().physics_frame.connect(apply_stats)
		return
	
	var statsDict: Dictionary
	for stat: String in StatsSynchronizerComponent.StatListWithDefaults:
		statsDict[stat] = stats_component.get(stat)
		
		#Apply all multipliers from classes for the given stat
		for charClass: CharacterClassResource in classes:
			statsDict[stat] *= charClass.get_multiplier(stat)
			
		#Apply all bonuses from classes
		for charClass: CharacterClassResource in classes:
			statsDict[stat] += charClass.get_bonus(stat)
	
	
func get_charclass_classes() -> Array[String]:
	var output: Array[String] = []
	for charClass: CharacterClassResource in classes:
		output.append(charClass.class_registered)
	return output
	
	
#Client only
func sync_all(id: int):
	#Calls self.sync_response
	G.sync_rpc.characterclasscomponent_sync_response.rpc_id(id, user.get_name(), to_json())


#Client only
func sync_response(data: Dictionary):
	from_json(data)
	
func to_json()->Dictionary:
	var output: Dictionary = {"classes": [], "blacklist": [], "whitelist": [], "max_classes": max_classes}
	
	for charClass: CharacterClassResource  in classes:
		output["classes"].append(charClass.class_registered)
		
	for charClass: String in class_blacklist:
		output["blacklist"].append(charClass)

	for charClass: String in class_whitelist:
		output["whitelist"].append(charClass)

	return output
	pass

func from_json(data: Dictionary) -> bool:
	for key: String in JSON_KEYS:
		if not key in data:
			GodotLogger.error('Failed to load classes from data, missing "{0}" key'.format([key]))
			return false
		
		set(key, data[key])
		
	return true
		

func is_full() -> bool:
	return classes.size() >= max_classes
		
		
## Returns wether or not this component is allowed to have this class 
func is_class_allowed(charclass:String) -> bool:
	if not class_whitelist.is_empty() and not charclass in class_whitelist:
		return false
	
	if charclass in class_blacklist:
		return false
	
	return true
