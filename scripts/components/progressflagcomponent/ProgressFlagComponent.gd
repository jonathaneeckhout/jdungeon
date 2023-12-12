extends Node
class_name ProgressFlagsComponent
## Simply stores String:bool pairs that other scripts can read to deduce the player's progress in the game.

signal flag_changed(flag: String, state: bool)

## Client only
signal sync_received

@export var user: Node

var flags_stored: Dictionary


func _ready() -> void:
	assert(user is Player)

	if G.is_server():
		flag_changed.connect(_on_flag_changed)

	if user.get("component_list") != null:
		user.component_list["progress_flags"] = self

	#Wait until the connection is ready
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server

	#Wait an additional frame so others can get set.
	await get_tree().process_frame

	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered

	#Retrieve ALL flags by not specifying any (empty Array)
	G.sync_rpc.progressflags_sync_flags.rpc_id(1, user.get_name(), [])


func set_flag_state(flagName: String, state: bool):
	flags_stored[flagName] = state
	flag_changed.emit(flagName, state)


func get_flag_state(flagName: String) -> bool:
	if not flags_stored.has(flagName):
		GodotLogger.warn("Flag not stored.")
		return false

	return flags_stored[flagName]


#Called and ran only on server
func sync_flags(id: int, flagsSpecified: Array):  #Change to Array[String] after this is fixed: https://github.com/godotengine/godot/issues/69215
	var flags: Dictionary = {}
	if flagsSpecified.is_empty():
		flags = flags_stored
	else:
		for flag: String in flagsSpecified:
			flags[flag] = flags_stored.get(flag, false)

	G.sync_rpc.progressflags_sync_flags_response.rpc_id(id, user.get_name(), flags)


#RPCd by server, ran only on client
func sync_response(flags: Dictionary):
	for flag: String in flags:
		flags_stored[flag] = flags[flag]

	sync_received.emit()


func from_json(data: Dictionary) -> bool:
	flags_stored = data
	return true


func to_json() -> Dictionary:
	return flags_stored


#Server only
func _on_flag_changed(flag: String, _state: bool):
	sync_flags(user.peer_id, [flag])
