extends Node

class_name ActionSynchronizerComponent

signal attacked(direction: Vector2)
signal skill_used(where: Vector2, skill_class: String)

@export var watcher_synchronizer: WatcherSynchronizerComponent

enum TYPE { ATTACK, SKILL_USE }

var target_node: Node
var peer_id: int = 0

var server_buffer: Array[Dictionary] = []


func _ready():
	target_node = get_parent()

	if target_node.get("peer_id") != null:
		peer_id = target_node.peer_id

	if not J.is_server():
		return


func _physics_process(_delta):
	_check_server_buffer()


func _check_server_buffer():
	for i in range(server_buffer.size() - 1, -1, -1):
		var entry = server_buffer[i]
		if entry["timestamp"] <= J.client.clock:
			match entry["type"]:
				TYPE.ATTACK:
					attacked.emit(entry["direction"])
				TYPE.SKILL_USE:
					skill_used.emit(entry["target_position"], entry["skill_class"])
			server_buffer.remove_at(i)

func skill_use(target_global_pos: Vector2, skill_class: String):
	var timestamp: float = Time.get_unix_time_from_system()
	
	for watcher in watcher_synchronizer.watchers:
		_sync_skill_use(timestamp, target_global_pos, skill_class)
		
	skill_used.emit(target_global_pos, skill_class)


func attack(direction: Vector2):
	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_sync_attack.rpc_id(peer_id, timestamp, direction)

	for watcher in watcher_synchronizer.watchers:
		_sync_attack.rpc_id(watcher.peer_id, timestamp, direction)

	attacked.emit(direction)

@rpc("call_remote", "authority", "reliable") func _sync_attack(t: float, d: Vector2):
	server_buffer.append({"type": TYPE.ATTACK, "timestamp": t, "direction": d})

@rpc("call_remote", "authority", "reliable")
func _sync_skill_use(timestamp: float, target_global_pos: Vector2, skill_class: String):
	server_buffer.append(
		{"type": TYPE.SKILL_USE, "timestamp": timestamp, "target_global_position": target_global_pos, "skill_class": skill_class}
	)
