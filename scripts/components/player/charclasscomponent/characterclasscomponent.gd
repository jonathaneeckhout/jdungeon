extends Node
class_name CharacterClassComponent

const COMPONENT_NAME: String = "class_component"

const CharacterClassSelectionScene: PackedScene = preload(
	"res://scripts/components/player/charclasscomponent/CharClassSelection.tscn"
)
const JSON_KEYS: Array[String] = ["classes", "class_whitelist", "class_blacklist", "max_classes"]
const SYNC_MINIMUM_INTERVAL: float = 1.0

signal classes_changed
signal class_lock_changed
signal list_changed

@export var user: Node

@export var stats_component: StatsSynchronizerComponent
@export var skill_component: SkillComponent

var classes: Array[CharacterClassResource]

## Only those here will be presented to the user, leave empty to disable
var class_whitelist: Array[String]

## Removes any option presented to the user that's defined here, taking precedence over [member class_whitelist]
var class_blacklist: Array[String]

## Max amount of simultaneous classes selected for this component
var max_classes: int = 1

## Class changes are prevented while this is true, used by the server to filter when a player should be capable of performing a change
var class_change_locked: bool = false:
	set(val):
		class_change_locked = val
		class_lock_changed.emit()

## Keep a menu to show the player, only client side
var classChangeMenu: CharacterClassSelectionMenu


func _ready():
	if user.get("component_list") != null:
		user.component_list["class_component"] = self

	classChangeMenu = CharacterClassSelectionScene.instantiate()
	classChangeMenu.select_target(self)

	#TEMP?
	if classes.is_empty():
		add_class("Base")

	#Re-apply stats anytime a class changes.
	if G.is_server():
		classes_changed.connect(apply_stats)
		classes_changed.connect(apply_skills)

	#This line should stay commented until there's a system to detect when a player should be allowed to change classes
	#class_change_locked = true

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

	G.sync_rpc.characterclasscomponent_sync_all.rpc_id(1, user.get_name())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("j_toggle_class_menu"):
		if classChangeMenu.is_inside_tree():
			classChangeMenu.close()
		else:
			user.ui_control.add_child(classChangeMenu)


func set_blacklist(charclass: String, enabled: bool):
	if enabled and not charclass in class_blacklist:
		class_blacklist.append(charclass)
	elif not enabled:
		class_blacklist.erase(charclass)
	list_changed.emit()


func set_whitelist(charclass: String, enabled: bool):
	if enabled and not charclass in class_whitelist:
		class_whitelist.append(charclass)
	elif not enabled:
		class_whitelist.erase(charclass)
	list_changed.emit()


func remove_class(charclass: String):
	if classes.is_empty():
		GodotLogger.warn("Tried to remove a class but there are none in this component.")
		return

	if not is_class_change_allowed():
		(
			GodotLogger
			. warn(
				"Tried to change classes, but this component is not allowed to do so at the present time."
			)
		)
		return

	# Clean the classes Array of any class matching this charclass
	var index: int = 0
	while index < classes.size():
		if classes[index].class_registered == charclass:
			classes.remove_at(index)
			classes_changed.emit()
			return
		index += 1


func add_class(charclass: String):
	if not is_class_change_allowed():
		(
			GodotLogger
			. warn(
				"Tried to change classes, but this component is not allowed to do so at the present time."
			)
		)
		return

	if charclass in get_charclass_classes():
		GodotLogger.warn("Tried to add a repeat class.")
		return

	if classes.size() >= max_classes:
		GodotLogger.warn(
			"Tried to add a class but the limit has already been reached for this component."
		)
		return

	if charclass in class_blacklist:
		GodotLogger.warn(
			"Attempted to add a blacklisted class '{0}', it was not added.".format([charclass])
		)
		return

	if not class_whitelist.is_empty() and not charclass in class_whitelist:
		GodotLogger.warn(
			(
				"Whitelist is enabled (not empty) but class '{0}' isn't in it, it was not added."
				. format([charclass])
			)
		)
		return

	var charClass: CharacterClassResource = J.charclass_resources[charclass].duplicate()
	classes.append(charClass)
	classes_changed.emit()


## Takes an Array[String] and uses it to replace all classes from the component
func replace_classes(newClasses: Array[String]):
	if not is_class_change_allowed():
		(
			GodotLogger
			. warn(
				"Tried to change classes, but this component is not allowed to do so at the present time."
			)
		)
		return

	if newClasses.size() > max_classes:
		GodotLogger.warn(
			"Tried to replace classes but the replacement Array is larger than the allowed size."
		)
		return

	#Remove the ones that don't belong
	var currentClasses: Array[String] = get_charclass_classes()
	for charclass: String in currentClasses:
		if not charclass in newClasses:
			remove_class(charclass)

	#Add the ones missing
	currentClasses = get_charclass_classes()
	for charclass: String in newClasses:
		#Not in, add it
		if not charclass in currentClasses:
			add_class(charclass)


## Applies bonuses and multipliers to the character's StatsSynchronizerComponent as a Boost object
func apply_stats():
	#If the stats are not ready, queue this for the next frame.
	if not stats_component.ready_done:
		get_tree().physics_frame.connect(apply_stats)
		return

	var statBoost := Boost.new()
	statBoost.identifier = "character_classes"

	for charClass: CharacterClassResource in classes:
		for stat: String in StatsSynchronizerComponent.StatListWithDefaults:
			#Apply all multipliers and bonuses from classes for the given stat
			statBoost.add_stat_boost(stat, charClass.get_bonus(stat))
			statBoost.add_stat_boost_modifier(stat, charClass.get_multiplier(stat), false)

	stats_component.apply_boost(statBoost)


func apply_skills():
	if not G.is_server():
		return

	#While this modifies skills, stats are the actual limiting factor as skill_component is always ready for use.
	if not stats_component.ready_done:
		get_tree().physics_frame.connect(apply_stats)
		return

	for existingSkill: String in skill_component.get_skills_classes():
		skill_component.remove_skill(existingSkill)

	for charClass: CharacterClassResource in classes:
		for skill: String in charClass.available_skills:
			skill_component.add_skill(skill)

	skill_component.sync_skills(user.peer_id)


func get_charclass_classes() -> Array[String]:
	var output: Array[String] = []
	for charClass: CharacterClassResource in classes:
		output.append(charClass.class_registered)
	return output


#Server only
func sync_all(id: int):
	#Calls self.sync_response
	G.sync_rpc.characterclasscomponent_sync_response.rpc_id(id, user.get_name(), to_json())


#Client only
func sync_response(data: Dictionary):
	from_json(data)


#Client only
func client_class_change_attempt(classList: Array[String] = get_charclass_classes()):
	assert(not G.is_server(), "This method is only intended for client use")
	if classList.is_empty():
		if Global.debug_mode:
			GodotLogger.warn("Ignored class change attempt with no classes selected.")
		return
	G.sync_rpc.characterclasscomponent_sync_class_change.rpc_id(1, user.get_name(), classList)


func to_json() -> Dictionary:
	var output: Dictionary = {
		"classes": [],
		"class_blacklist": [],
		"class_whitelist": [],
		"max_classes": max_classes as int
	}

	for charClass: CharacterClassResource in classes:
		output["classes"].append(charClass.class_registered as String)

	for charClass: String in class_blacklist:
		output["class_blacklist"].append(charClass)

	for charClass: String in class_whitelist:
		output["class_whitelist"].append(charClass)

	return output


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
func is_class_allowed(charclass: String) -> bool:
	if not class_whitelist.is_empty() and not charclass in class_whitelist:
		return false

	if charclass in class_blacklist:
		return false

	return true


func is_class_change_allowed() -> bool:
	if class_change_locked:
		return false

	return true
