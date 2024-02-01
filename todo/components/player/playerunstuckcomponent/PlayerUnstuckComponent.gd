extends Node

class_name PlayerUnstuckComponent

@export var stats: StatsSynchronizerComponent

var target_node: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	target_node = get_parent()


func unstuck():
	GodotLogger.info("Unstucking player")
	_unstuck.rpc_id(1)


@rpc("call_remote", "any_peer", "reliable")
func _unstuck():
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		stats.kill()
