extends Resource
class_name CharacterClassResource

const FAILSAFE_ICON_PATH: String = "res://icon.svg"

@export var displayed_name: String

## The internal name used for referencing this
@export var class_registered: StringName

## This path is used to retrieve it's icon, avoid storing the texture directly for server memory reason
@export_file("*.jpg *.png *.svg") var icon_path: String

@export_multiline var description: String

## Any skill_class defined here will be made available for a character using this class
## Other requirements may be added
@export var available_skills: Array[String]

## Stored as a String:float pair
## These multipliers should be used on StatsComponent, use the name of the stat's variable followed by the multiplier
## All values default to 1
@export var stat_multipliers: Dictionary = {
	"hp_max": 1.0,
	"energy_max": 1.0,
	"energy_regen": 1.0,
	"attack_power_min": 1.0,
	"attack_power_max": 1.0,
	"defense": 1.0,
	"movement_speed": 1.0,
}

## Stored as a String:int pair
## Similar to stat_multipliers, but with flat bonuses.
## All values default to 0
@export var stat_bonuses: Dictionary = {
	"hp_max": 0,
	"energy_max": 0,
	"energy_regen": 0,
	"attack_power_min": 0,
	"attack_power_max": 0,
	"defense": 0,
	"movement_speed": 0,
}


func get_multiplier(stat: String) -> float:
	return stat_multipliers.get(stat, 1.0 as float)


func get_bonus(stat: String) -> int:
	return stat_bonuses.get(stat, 0 as int)


func get_icon() -> Texture:
	var returnedIcon: Texture = load(icon_path)
	if returnedIcon is Texture:
		return returnedIcon
	else:
		GodotLogger.error(
			"Cannot load icon for class {0} using path {1}".format([displayed_name, icon_path])
		)
		return load(FAILSAFE_ICON_PATH)
