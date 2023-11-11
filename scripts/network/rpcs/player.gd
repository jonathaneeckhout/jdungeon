extends Node

class_name PlayerRPC

signal player_added(id: int, username: String, pos: Vector2)
signal other_player_added(username: String, pos: Vector2, loop_animation: String)
signal other_player_removed(username: String)
signal message_sent(from: int, type: String, to: String, message: String)
signal message_received(type: String, from: String, message: String)

@rpc("call_remote", "authority", "reliable")
func add_player(id: int, username: String, pos: Vector2):
	player_added.emit(id, username, pos)


@rpc("call_remote", "any_peer", "reliable") func get_player():
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var user: G.User = G.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		return

	if user.player == null:
		GodotLogger.warn("User=%s has no player" % user.username)
		return

	G.player_rpc.add_player.rpc_id(id, id, user.username, user.player.position)


@rpc("call_remote", "authority", "reliable")
func add_other_player(username: String, pos: Vector2, loop_animation: String):
	other_player_added.emit(username, pos, loop_animation)


@rpc("call_remote", "authority", "reliable") func remove_other_player(username: String):
	other_player_removed.emit(username)


@rpc("call_remote", "any_peer", "reliable")
func send_message(type: String, to: String, message: String):
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	message_sent.emit(id, type, to, message)


@rpc("call_remote", "authority", "reliable")
func receive_message(type: String, from: String, message: String):
	message_received.emit(type, from, message)
