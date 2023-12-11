extends Node
class_name ProgressFlagsComponent

var flag_system: ProgressFlagSystem

var flags_stored: Dictionary

func get_flag(flagName: String) -> bool:
	if not flags_stored.has(flagName):
		GodotLogger.warn("Flag not stored.")
		return false
		
	return flags_stored[flagName]

func sync_flags():
	
