extends Node

class_name ActionSynchronizerComponent

signal attacked(target: String, damage: int)

@export var watcher_synchronizer: WatcherSynchronizerComponent

enum TYPE { ATTACK }

var target_node: Node

var server_buffer: Array[Dictionary] = []


func _ready():
	target_node = get_parent()

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
					attacked.emit(entry["target"], entry["damage"])
			server_buffer.remove_at(i)


func attack(target: String, damage: int):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watcher_synchronizer.watchers:
		_sync_attack.rpc_id(watcher.peer_id, timestamp, target, damage)

	attacked.emit(target, damage)


@rpc("call_remote", "authority", "reliable")
func _sync_attack(timestamp: float, target: String, damage: int):
	server_buffer.append(
		{"type": TYPE.ATTACK, "timestamp": timestamp, "target": target, "damage": damage}
	)
