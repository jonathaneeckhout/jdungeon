extends Node

var database: Node

var users = {}


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func init() -> bool:
	database = load("res://gmf/server/scripts/database/database.gd").new()
	database.name = "Database"
	add_child(database)

	if not database.init():
		GMF.logger.err("Failed to init server's database")
		return false

	return true


func get_tls_options() -> TLSOptions:
	var cert_file = FileAccess.open(GMF.global.env_server_crt, FileAccess.READ)
	if cert_file == null:
		GMF.logger.warn("Failed to open server certificate %s" % GMF.global.env_server_crt)
		return null

	var key_file = FileAccess.open(GMF.global.env_server_key, FileAccess.READ)
	if key_file == null:
		GMF.logger.warn("Failed to open server key %s" % GMF.global.env_server_key)
		return null

	var cert_string = cert_file.get_as_text()
	var key_string = key_file.get_as_text()

	var cert = X509Certificate.new()

	var error = cert.load_from_string(cert_string)
	if error != OK:
		GMF.logger.warn("Failed to load certificate")
		return null

	var key = CryptoKey.new()

	error = key.load_from_string(key_string)
	if error != OK:
		GMF.logger.warn("Failed to load key")
		return null

	return TLSOptions.server(key, cert)


func start() -> bool:
	var server = ENetMultiplayerPeer.new()

	var error = server.create_server(GMF.global.env_server_port, GMF.global.env_server_max_peers)
	if error != OK:
		GMF.logger.warn("Failed to create server")
		return false

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GMF.logger.warn("Failed to start server")
		return false

	var server_tls_options = get_tls_options()
	if server_tls_options == null:
		GMF.logger.warn("Failed to load tls options")
		return false

	error = server.host.dtls_server_setup(server_tls_options)
	if error != OK:
		GMF.logger.warn("Failed to setup DTLS")
		return false

	multiplayer.multiplayer_peer = server

	GMF.logger.info("Started DTLS server")

	return true


func _on_peer_connected(id: int):
	GMF.logger.info("Peer connected %d" % id)
	users[id] = {
		"username": "", "logged_in": false, "connected_time": Time.get_unix_time_from_system()
	}


func _on_peer_disconnected(id: int):
	GMF.logger.info("Peer disconnected %d" % id)
	users.erase(id)
