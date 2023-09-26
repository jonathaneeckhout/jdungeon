extends Node

signal account_created(response: Dictionary)
signal authenticated(response: bool)

signal player_logged_in(id: int, username: String)

@rpc("call_remote", "any_peer", "reliable") func create_account(username, password):
	if not J.is_server():
		return

	J.logger.info("Creating account for user=[%s]" % username)
	var id = multiplayer.get_remote_sender_id()

	if J.server.database.create_account(username, password):
		create_account_response.rpc_id(id, false, "Account created")
	else:
		create_account_response.rpc_id(id, true, "Failed to create account")


@rpc("call_remote", "authority", "reliable")
func create_account_response(error: bool, reason: String = ""):
	account_created.emit({"error": error, "reason": reason})


@rpc("call_remote", "any_peer", "reliable") func authenticate(username, password):
	if not J.is_server():
		return

	J.logger.info("Authenticating user=[%s]" % username)
	var id = multiplayer.get_remote_sender_id()

	var res = J.server.database.authenticate_user(username, password)

	J.server.users[id]["logged_in"] = res

	if res:
		player_logged_in.emit(id, username)

	authentication_response.rpc_id(id, res)


@rpc("call_remote", "authority", "reliable") func authentication_response(response: bool):
	authenticated.emit(response)