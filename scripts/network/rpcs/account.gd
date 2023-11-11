extends Node

class_name AccountRPC

signal account_created(response: Dictionary)
signal authenticated(response: bool)

signal player_logged_in(id: int, username: String)

@rpc("call_remote", "any_peer", "reliable") func create_account(username, password):
	if not G.is_server():
		return

	GodotLogger.info("Creating account for user=[%s]" % username)
	var id: int = multiplayer.get_remote_sender_id()

	var create_account_result: Dictionary = G.database.create_account(username, password)
	if create_account_result["result"]:
		create_account_response.rpc_id(id, false, "Account created")
	else:
		create_account_response.rpc_id(id, true, create_account_result["error"])


@rpc("call_remote", "authority", "reliable")
func create_account_response(error: bool, reason: String = ""):
	account_created.emit({"error": error, "reason": reason})


@rpc("call_remote", "any_peer", "reliable") func authenticate(username, password):
	if not G.is_server():
		return

	GodotLogger.info("Authenticating user=[%s]" % username)
	var id = multiplayer.get_remote_sender_id()

	var res = G.database.authenticate_user(username, password)

	var user: G.User = G.users[id]
	user.logged_in = res

	if res:
		GodotLogger.info("Player=[%s] successfully logged in" % username)
		user.username = username
		player_logged_in.emit(id, username)

	authentication_response.rpc_id(id, res)


@rpc("call_remote", "authority", "reliable") func authentication_response(response: bool):
	authenticated.emit(response)
