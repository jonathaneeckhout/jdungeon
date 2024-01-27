extends MultiplayerConnection

class_name WebsocketMultiplayerConnection

## Wether or not the connection should use tls
@export var use_tls: bool = false

## The url to which the client should connect to
@export var client_server_url: String = "ws://localhost:9070"

## The port used by the server
@export var server_port: int = 9070

## The address to which the server should bind to
@export var server_bind_address: String = "*"

## The path of the server certificate
@export var server_cert_path: String = ""

## The path of the server key
@export var server_key_path: String = ""

# The server for this connection
var _server: WebSocketMultiplayerPeer = null

# The client for this connection
var _client: WebSocketMultiplayerPeer = null


## Init the websocket client
func websocket_client_init() -> bool:
	GodotLogger.info("Initializing the websocket client")

	return _client_init()


## Client start function to be called after the inherited class client start
func websocket_client_start(url: String = client_server_url) -> bool:
	_client = WebSocketMultiplayerPeer.new()

	GodotLogger.info("Connecting to websocket server:[%s]" % url)
	var error: int = _client.create_client(url)

	if error != OK:
		GodotLogger.warn(
			"Failed to create client. Error code {0} ({1})".format([error, error_string(error)])
		)
		return false

	# Assign the client to the default multiplayer peer
	multiplayer_api.multiplayer_peer = _client

	_client_start()

	return true


## Disconnect the client from the server
func websocket_client_disconnect():
	GodotLogger.info("Disconnecting client from server")

	_client_cleanup()

	if _client != null:
		_client.close()
		_client = null


## Init the websocket server
func websocket_server_init() -> bool:
	GodotLogger.info("Initializing the websocket server")

	return _server_init()


## Start the websocket server
func websocket_server_start(
	port: int = server_port,
	bind_address: String = server_bind_address,
	tls: bool = use_tls,
	cert_path: String = server_cert_path,
	key_path: String = server_key_path
) -> bool:
	_server = WebSocketMultiplayerPeer.new()
	GodotLogger.info(
		"Starting websocket server on port[%d] and binding to address=[%s]" % [port, bind_address]
	)

	if tls:
		# Get the tls optiojns
		var server_tls_options: TLSOptions = server_get_tls_options(cert_path, key_path)
		if server_tls_options == null:
			GodotLogger.error("Failed to start websocket server, loading of the tls options failed")
			return false

		var error: int = _server.create_server(port, bind_address, server_tls_options)
		if error != OK:
			GodotLogger.error("Failed to start websocket server, failed to create server")
			return false
	else:
		var error: int = _server.create_server(port, bind_address)
		if error != OK:
			GodotLogger.error("Failed to start websocket server, failed to create server")
			return false

	if _server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GodotLogger.error("Failed to start websocket server, disconnected state")
		return false

	# Assign the client to the default multiplayer peer
	multiplayer_api.multiplayer_peer = _server

	_server_start()

	GodotLogger.info("Successfully starter websocket server")

	return true
