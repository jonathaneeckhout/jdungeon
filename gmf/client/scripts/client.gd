extends Node

const CLOCK_SYNC_TIMER_TIME = 0.5

var clock: float = 0.0
var clock_sync_timer: Timer


func _ready():
	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	clock_sync_timer = Timer.new()
	clock_sync_timer.wait_time = CLOCK_SYNC_TIMER_TIME
	clock_sync_timer.timeout.connect(_on_clock_sync_timer_timeout)
	add_child(clock_sync_timer)


func connect_to_server(address, port) -> bool:
	var client = ENetMultiplayerPeer.new()

	var error = client.create_client(address, port)
	if error != OK:
		Gmf.logger.warn("Failed to create client")
		return false

	if client.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		Gmf.logger.warn("Failed to connect to server")
		return false

	var client_tls_options: TLSOptions

	if Gmf.global.env_debug:
		client_tls_options = TLSOptions.client_unsafe()
	else:
		client_tls_options = TLSOptions.client()

	error = client.host.dtls_client_setup(address, client_tls_options)
	if error != OK:
		Gmf.logger.warn("Failed to connect via DTLS")
		return false

	multiplayer.multiplayer_peer = client

	return true


func start_sync_clock():
	Gmf.rpcs.clock.fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	clock_sync_timer.start(CLOCK_SYNC_TIMER_TIME)


func stop_sync_clock():
	clock_sync_timer.stop()


func _on_connection_succeeded():
	Gmf.logger.info("Connection succeeded")
	Gmf.signals.client.connected.emit(true)

	start_sync_clock()


func _on_server_disconnected():
	Gmf.logger.info("Server disconnected")
	Gmf.signals.client.connected.emit(false)

	stop_sync_clock()


func _on_connection_failed():
	Gmf.logger.warn("Connection failed")
	Gmf.signals.client.connected.emit(false)


func _on_clock_sync_timer_timeout():
	Gmf.rpcs.clock.get_latency.rpc_id(1, Time.get_unix_time_from_system())
