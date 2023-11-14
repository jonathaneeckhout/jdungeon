extends Node

class_name ServerRPC

signal server_registered(response: bool)

@rpc("call_remote", "any_peer", "reliable")
func register_server(server_name: String, address: String, port: int):
	if not S.is_server():
		return

	var id: int = S.multiplayer_api.get_remote_sender_id()

	var server: S.Server = S.get_server_by_id(id)
	if server == null:
		GodotLogger.warn("Failed to get server with peer id=[%d]" % id)
		register_response.rpc_id(id, false)
		return

	server.name = server_name
	server.peer_id = id
	server.address = address
	server.port = port

	GodotLogger.info(
		(
			"Server=[%s] with address=[%s] running on port=[%d] registered"
			% [server_name, address, port]
		)
	)

	register_response.rpc_id(id, true)


@rpc("call_remote", "authority", "reliable") func register_response(response: bool):
	server_registered.emit(response)


@rpc("call_remote", "authority", "reliable") func register_user(username: String, cookie: String):
	S.register_user(username, cookie)
