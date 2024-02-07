extends Node

class_name DTLSNetworking


func server_init(
	port: int, max_clients: int, cert_path: String, key_path: String
) -> ENetMultiplayerPeer:
	var server: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

	var error = server.create_server(port, max_clients)
	if error != OK:
		GodotLogger.error("Failed to create server")
		return null

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GodotLogger.error("Failed to start server")
		return null

	if not Global.env_no_tls:
		var server_tls_options = server_get_tls_options(cert_path, key_path)
		if server_tls_options == null:
			GodotLogger.error("Failed to load tls options")
			return null

		error = server.host.dtls_server_setup(server_tls_options)
		if error != OK:
			GodotLogger.error("Failed to setup DTLS")
			return null

	return server


func server_get_tls_options(cert_path: String, key_path: String) -> TLSOptions:
	if not FileAccess.file_exists(cert_path):
		GodotLogger.error("Certificate=[%s] does not exist" % cert_path)
		return null

	if not FileAccess.file_exists(key_path):
		GodotLogger.error("Key=[%s] does not exist" % key_path)
		return null

	var cert_file = FileAccess.open(cert_path, FileAccess.READ)
	if cert_file == null:
		GodotLogger.error("Failed to open server certificate %s" % cert_path)
		return null

	var key_file = FileAccess.open(key_path, FileAccess.READ)
	if key_file == null:
		GodotLogger.error("Failed to open server key %s" % key_path)
		return null

	var cert_string = cert_file.get_as_text()
	var key_string = key_file.get_as_text()

	var cert = X509Certificate.new()

	var error = cert.load_from_string(cert_string)
	if error != OK:
		GodotLogger.error("Failed to load certificate")
		return null

	var key = CryptoKey.new()

	error = key.load_from_string(key_string)
	if error != OK:
		GodotLogger.error("Failed to load key")
		return null

	return TLSOptions.server(key, cert)


func client_connect(address: String, port: int) -> ENetMultiplayerPeer:
	var client: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

	var error: int = client.create_client(address, port)
	if error != OK:
		GodotLogger.warn(
			"Failed to create client. Error code {0} ({1})".format([error, error_string(error)])
		)
		return null

	if client.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GodotLogger.warn("Failed to connect to server")
		return null

	if not Global.env_no_tls:
		var client_tls_options: TLSOptions

		if Global.env_debug:
			client_tls_options = TLSOptions.client_unsafe()
		else:
			client_tls_options = TLSOptions.client()

		error = client.host.dtls_client_setup(address, client_tls_options)
		if error != OK:
			GodotLogger.warn(
				"Failed to connect via DTLS. Error code {0} ({1})".format(
					[error, error_string(error)]
				)
			)
			return null

	return client


func add_database(target: Node) -> Database:
	var database = Database.new()
	database.name = "Database"
	target.add_child(database)

	if not database.init():
		GodotLogger.error("Failed to init server's database")
		target.remove_child(database)
		return null

	return database
