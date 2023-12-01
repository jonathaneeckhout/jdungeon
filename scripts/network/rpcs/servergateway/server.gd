extends Node

class_name ServerRPC

signal server_registered(response: bool)
signal user_portalled(
	response: bool,
	username: String,
	server_name: String,
	portal_position: Vector2,
	address: String,
	port: int,
	cookie: String
)

@rpc("call_remote", "any_peer", "reliable")
func register_server(server_name: String, address: String, port: int, portals_info: Dictionary):
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
	server.portals_info = portals_info

	GodotLogger.info(
		(
			"Server=[%s] with address=[%s] running on port=[%d] registered"
			% [server_name, address, port]
		)
	)

	register_response.rpc_id(id, true)


@rpc("call_remote", "authority", "reliable")
func register_response(response: bool):
	server_registered.emit(response)


@rpc("call_remote", "authority", "reliable")
func register_user(username: String, cookie: String):
	S.register_user(username, cookie)


@rpc("call_remote", "any_peer", "reliable")
func enter_portal(username: String, server_name: String, portal_name: String):
	if not S.is_server():
		return

	var id: int = S.multiplayer_api.get_remote_sender_id()

	# Check if the server is registered
	var server: S.Server = S.get_server_by_name(server_name)
	if server == null:
		GodotLogger.warn("Failed to get server with name=[%s]" % server_name)
		portal_response.rpc_id(id, false, username, "", Vector2.ZERO, "", 0, "")
		return

	# Check if the server has the portal
	var portal_info: Dictionary = server.portals_info.get(portal_name)
	if portal_info == null:
		GodotLogger.warn("Server=[%s] does not have portal=[%s]" % [server_name, portal_name])
		portal_response.rpc_id(id, false, username, "", Vector2.ZERO, "", 0, "")
		return

	# Create an unique cookie
	var cookie: String = J.uuid_util.v4()

	# Register the user on the server side
	GodotLogger.info("Registering user=[%s] on server=[%s]" % [username, server.name])
	register_user.rpc_id(server.peer_id, username, cookie)

	# Sending back the information the the server so that a client can switch to the new server
	portal_response.rpc_id(
		id,
		true,
		username,
		server.name,
		portal_info["position"],
		server.address,
		server.port,
		cookie
	)


@rpc("call_remote", "authority", "reliable")
func portal_response(
	response: bool,
	username: String,
	server_name: String,
	portal_position: Vector2,
	address: String,
	port: int,
	cookie: String
):
	user_portalled.emit(response, username, server_name, portal_position, address, port, cookie)
