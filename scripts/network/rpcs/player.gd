extends Node

signal player_added(id: int, username: String, pos: Vector2)
signal other_player_added(username: String, pos: Vector2)
signal other_player_removed(username: String)

@rpc("call_remote", "authority", "reliable")
func add_player(id: int, username: String, pos: Vector2):
	player_added.emit(id, username, pos)


@rpc("call_remote", "authority", "reliable") func add_other_player(username: String, pos: Vector2):
	other_player_added.emit(username, pos)


@rpc("call_remote", "authority", "reliable") func remove_other_player(username: String):
	other_player_removed.emit(username)
