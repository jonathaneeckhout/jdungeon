extends Node

class_name ActionSynchronizerComponent

signal attacked(direction: Vector2)

@export var watcher_synchronizer: WatcherSynchronizerComponent

enum TYPE { ATTACK }

var target_node: Node
var peer_id: int = 0

var server_buffer: Array[Dictionary] = []


func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list["action_synchronizer"] = self

	if target_node.get("peer_id") != null:
		peer_id = target_node.peer_id

	if not G.is_server():
		return


func _physics_process(_delta):
	_check_server_buffer()


func _check_server_buffer():
	for i in range(server_buffer.size() - 1, -1, -1):
		var entry = server_buffer[i]
		if entry["timestamp"] <= G.clock:
			match entry["type"]:
				TYPE.ATTACK:
					attacked.emit(entry["direction"])
			server_buffer.remove_at(i)


func attack(direction: Vector2):
	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		G.sync_rpc.actionsynchronizer_sync_attack.rpc_id(
			peer_id, target_node.name, timestamp, direction
		)

	for watcher in watcher_synchronizer.watchers:
		G.sync_rpc.actionsynchronizer_sync_attack.rpc_id(
			watcher.peer_id, target_node.name, timestamp, direction
		)

	attacked.emit(direction)


func sync_attack(t: float, d: Vector2):
	server_buffer.append({"type": TYPE.ATTACK, "timestamp": t, "direction": d})
