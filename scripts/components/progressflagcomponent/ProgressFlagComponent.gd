extends Node
class_name ProgressFlagsComponent

#var flag_system: ProgressFlagSystem
var flags_stored: Dictionary

var target_node: Node

func _ready() -> void:
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list["progress_flags"] = self
		

func get_flag(flagName: String) -> bool:
	if not flags_stored.has(flagName):
		GodotLogger.warn("Flag not stored.")
		return false
		
	return flags_stored[flagName]

func sync_flags(flagsSelected: Array): #Array[String], temporarily removed typecast due to a Godot bug
	G.sync_rpc.progressflags_sync_flags.rpc_id(1, flagsSelected)

func sync_response(flags: Dictionary):
	flags_stored = flags
