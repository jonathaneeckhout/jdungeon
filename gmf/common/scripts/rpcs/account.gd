extends Node

@rpc("call_remote", "any_peer", "reliable") func create_account(username, password):
	if not GMF.is_server():
		return

	GMF.logger.info("Creating account for user=[%s]" % username)
	var id = multiplayer.get_remote_sender_id()

	if GMF.server.database.create_account(username, password):
		create_account_response.rpc_id(id, false, "Account created")
	else:
		create_account_response.rpc_id(id, true, "Failed to create account")


@rpc("call_remote", "authority", "reliable")
func create_account_response(error: bool, reason: String = ""):
	GMF.signals.client.account_created.emit({"error": error, "reason": reason})


@rpc("call_remote", "any_peer", "reliable") func authenticate(username, password):
	if not GMF.is_server():
		return

	GMF.logger.info("Authenticating user=[%s]" % username)
	var id = multiplayer.get_remote_sender_id()

	var res = GMF.server.database.authenticate_user(username, password)

	GMF.server.users[id]["logged_in"] = res

	if res:
		GMF.signals.server.player_logged_in.emit(id, username)

	authentication_response.rpc_id(id, res)


@rpc("call_remote", "authority", "reliable") func authentication_response(response: bool):
	GMF.signals.client.authenticated.emit(response)
