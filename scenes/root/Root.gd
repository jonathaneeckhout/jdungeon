extends Node

const SERVER_FPS: int = 20
const CLIENT_FPS: int = 60

@onready var ui: CanvasLayer = $UI
@onready var select_run_mode: Control = $UI/SelectRunMode
@onready var select_mode_buttons: VBoxContainer = $UI/SelectRunMode/SelectModeButtons
@onready var run_as_gateway_button: Button = $UI/SelectRunMode/SelectModeButtons/RunAsGatewayButton
@onready var run_as_server_button: Button = $UI/SelectRunMode/SelectModeButtons/RunAsServerButton
@onready var run_as_client_button: Button = $UI/SelectRunMode/SelectModeButtons/RunAsClientButton

@onready var select_map: VBoxContainer = $UI/SelectRunMode/SelectMap
@onready var map_option_button: OptionButton = $UI/SelectRunMode/SelectMap/MapOptionButton
@onready var start_server_button: Button = $UI/SelectRunMode/SelectMap/StartServerButton

var login_panel_scene: Resource = preload("res://scenes/ui/loginpanel/LoginPanel.tscn")
var version_check_panel_scene: Resource = preload(
	"res://scenes/ui/versioncheckpanel/VersionCheckPanel.tscn"
)
var disclaimer_panel_scene: Resource = preload(
	"res://scenes/ui/disclaimerpanel/DisclaimerPanel.tscn"
)

var map_option_selected: int = 0


func _ready():
	run_as_gateway_button.pressed.connect(_on_run_as_gateway_pressed)
	run_as_server_button.pressed.connect(_on_run_as_server_pressed)
	run_as_client_button.pressed.connect(_on_run_as_client_pressed)

	if Global.env_run_as_gateway:
		start_gateway()
	elif Global.env_run_as_server:
		start_server()
	elif Global.env_run_as_client:
		start_client()
	else:
		parse_cmd_arguments()


func parse_cmd_arguments():
	var args: PackedStringArray = OS.get_cmdline_args()
	if not args.is_empty():
		GodotLogger.info("Found launch arguments. ", str(args))

	for arg in args:
		match arg:
			"j_gateway":
				start_gateway()
				break

			"j_server":
				start_server()
				break

			"j_client":
				start_client()
				break


func start_gateway() -> bool:
	GodotLogger.info("Running as Gateway")

	select_run_mode.queue_free()

	GodotLogger.info("Loading gateway's env variables")
	if not Global.load_gateway_env_variables():
		GodotLogger.error("Could not load gateway's env variables")
		return false

	if Global.env_minimize_on_start:
		get_tree().root.mode = Window.MODE_MINIMIZED

	if not S.server_init(
		Global.env_gateway_server_port,
		Global.env_gateway_server_max_peers,
		Global.env_gateway_server_crt,
		Global.env_gateway_server_key
	):
		GodotLogger.error("Failed to start gateway client DTLS server")
		return false

	if not C.server_init(
		Global.env_gateway_client_port,
		Global.env_gateway_client_max_peers,
		Global.env_gateway_client_crt,
		Global.env_gateway_client_key
	):
		GodotLogger.error("Failed to start gateway client DTLS server")
		return false

	GodotLogger.info("Gateway successfully started")
	get_window().title = "JDungeon (Gateway)"
	return true


func start_server() -> bool:
	GodotLogger.info("Running as server")

	GodotLogger.info("Setting server's engine fps to %d" % SERVER_FPS)
	Engine.set_physics_ticks_per_second(SERVER_FPS)

	GodotLogger.info("Loading server's env variables")
	if not Global.load_server_env_variables():
		GodotLogger.error("Could not load server's env variables")
		return false

	J.register_scenes()

	var map: String = ""

	if Global.env_server_map != "":
		map = Global.env_server_map
	else:
		# Populate the options
		for map_name in J.map_scenes:
			map_option_button.add_item(map_name)
		select_mode_buttons.hide()
		select_map.show()
		map_option_button.item_selected.connect(_on_map_option_selected)

		await start_server_button.pressed
		map = map_option_button.get_item_text(map_option_selected)

		# Make sure to use different ports for each server
		Global.env_server_port += map_option_selected

		map_option_button.item_selected.disconnect(_on_map_option_selected)
		select_map.hide()

	GodotLogger.info("Starting server with map %s" % map)

	select_run_mode.queue_free()

	if Global.env_minimize_on_start:
		get_tree().root.mode = Window.MODE_MINIMIZED

	if not S.client_init():
		GodotLogger.error("Failed to connect to gateway")
		return false

	if not G.server_init(
		Global.env_server_port,
		Global.env_server_max_peers,
		Global.env_server_crt,
		Global.env_server_key
	):
		GodotLogger.error("Failed to start DTLS server")
		return false

	var server_fsm: ServerFSM = ServerFSM.new()
	server_fsm.name = "ServerFSM"
	server_fsm.map_name = map
	add_child(server_fsm)

	GodotLogger.info("Server successfully started on port %d" % Global.env_server_port)
	get_window().title = "JDungeon (Server)"
	return true


func start_client() -> bool:
	GodotLogger.info("Running as client")
	select_run_mode.queue_free()

	GodotLogger.info("Setting client's engine fps to %d" % CLIENT_FPS)
	Engine.set_physics_ticks_per_second(CLIENT_FPS)

	GodotLogger.info("Loading local settings")
	Global.load_local_settings()

	GodotLogger.info("Loading client's env variables")
	if not Global.load_client_env_variables():
		GodotLogger.error("Could not load client's env variables")
		return false

	J.register_scenes()

	if not C.client_init():
		GodotLogger.error("Failed to init gateway client")
		return false

	if not G.client_init():
		GodotLogger.error("Failed to init gameserver client")
		return false

	if not Global.env_debug:
		# Show the check version panel
		var version_check_panel: VersionCheckPanel = version_check_panel_scene.instantiate()
		ui.add_child(version_check_panel)

		if await version_check_panel.check_version():
			version_check_panel.queue_free()

			var disclaimer_panel: DisclaimerPanel = disclaimer_panel_scene.instantiate()
			ui.add_child(disclaimer_panel)

			await disclaimer_panel.accepted

			disclaimer_panel.queue_free()
		else:
			GodotLogger.error(
				"Client's version does not match the Server's version. Not the running game."
			)
			return false

	var login_panel: LoginPanel = login_panel_scene.instantiate()
	ui.add_child(login_panel)

	var client_fsm: ClientFSM = ClientFSM.new()
	client_fsm.name = "ClientFSM"
	client_fsm.login_panel = login_panel
	add_child(client_fsm)

	GodotLogger.info("Client successfully started")
	get_window().title = "JDungeon (Client)"
	return true


func _on_run_as_gateway_pressed():
	GodotLogger._prefix = "GatewayServer"
	start_gateway()


func _on_run_as_server_pressed():
	GodotLogger._prefix = "GameServer"
	start_server()


func _on_run_as_client_pressed():
	GodotLogger._prefix = "Client"
	start_client()


func _on_map_option_selected(index):
	print(index)
	map_option_selected = index
