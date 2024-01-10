extends Node

# This is the entrypoint of the JDungeon project
# Signletons used in this project:
# GodotLogger -> use this singleton to log message
# Global -> singleton that contains env variable settings and local settings
# J -> this singleton contains all the scenes and resources used in the game
# G -> Gameserver singleton
# C -> Gateway's side for the clients to connect to
# S -> Gateway's side for the gameservers to connect to
# JUI -> Singleton to keep track of some ui related stuff

## FPS used on the gameserver side
const SERVER_FPS: int = 20

## FPS used on the client-side
const CLIENT_FPS: int = 60

const GAME_ICONS: Array[Texture] = [
	preload("res://assets/images/enemies/boar/scaled/example.png"),
	preload("res://assets/images/enemies/flower/scaled/Flower.png"),
	preload("res://assets/images/enemies/moldeddruvar/scaled/moldeddruvar.png"),
	preload("res://assets/images/enemies/sheep/scaled/sheep.png"),
]

const SERVER_SUB_ICON: Texture = preload("res://assets/images/ui/cursors/LootCursor.png")
const GATEWAY_SUB_ICON: Texture = preload("res://assets/images/ui/cursors/TalkCursor.png")

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

# Variable to keep track which map option is selected in the map selection menu
var _map_option_selected: int = 0


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
	set_game_icon(GAME_ICONS.pick_random(), GATEWAY_SUB_ICON)

	GodotLogger._prefix = "GatewayServer"

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
	set_game_icon(GAME_ICONS.pick_random(), SERVER_SUB_ICON)

	# Set the prefix for all the logs on this instance
	GodotLogger._prefix = "GameServer"

	GodotLogger.info("Running as server")

	# set the fps on the server-side, this is typically slower than the client-side
	GodotLogger.info("Setting server's engine fps to %d" % SERVER_FPS)

	Engine.set_physics_ticks_per_second(SERVER_FPS)

	# Load the env variables for the server
	GodotLogger.info("Loading server's env variables")

	if not Global.load_server_env_variables():
		GodotLogger.error("Could not load server's env variables")

		return false

	# Register all the scenes so that they can accesses via the J singleton in the rest of the project
	J.register_scenes()

	# Start the map selection
	var map: String = await _server_get_map()

	GodotLogger.info("Starting server with map %s" % map)

	# Remove the select run mode menu as it will not be used anymore
	select_run_mode.queue_free()

	# Minimize the window if this env variable is set
	if Global.env_minimize_on_start:
		get_tree().root.mode = Window.MODE_MINIMIZED

	# Create the gameserver's fsm, this script will further handle the startup of the server
	var server_fsm: ServerFSM = ServerFSM.new()
	server_fsm.name = "ServerFSM"
	server_fsm.map_name = map
	add_child(server_fsm)

	# Set the title of the window
	get_window().title = "JDungeon (Gameserver)"

	return true


# Get the map which will be used for the gameserver side
func _server_get_map() -> String:
	var map: String = ""

	# If the env variable is set, use this one
	if Global.env_server_map != "":
		map = Global.env_server_map

	# If not, use the map selection menu
	else:
		# Populate the menu options
		for map_name in J.map_scenes:
			map_option_button.add_item(map_name)

		# Hide the previous menu
		select_mode_buttons.hide()

		# Show the map selection menu
		select_map.show()

		# Connect to the selection signal
		map_option_button.item_selected.connect(_on__map_option_selected)

		# Wait until the start button is pressed
		await start_server_button.pressed

		# Take the current selected option as map
		map = map_option_button.get_item_text(_map_option_selected)

		# This line is to make sure that when running multiple instances of server that they all have different ports
		Global.env_server_port += _map_option_selected

		# Disconnect from the signal
		map_option_button.item_selected.disconnect(_on__map_option_selected)

		# Hide the map selection menu
		select_map.hide()

		# Show the previous menu
		select_mode_buttons.show()

	return map


func start_client() -> bool:
	set_game_icon(GAME_ICONS.pick_random())

	GodotLogger._prefix = "Client"

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


func set_game_icon(icon: Texture, sub_icon: Texture = null):
	var image: Image = icon.get_image()
	image.resize(64, 64)

	if sub_icon is Texture:
		var sub_image: Image = sub_icon.get_image()
		sub_image.resize(32, 32)

		var initial_pos := Vector2i(32, 32)

		for width: int in sub_image.get_width():
			for height: int in sub_image.get_height():
				var pixel_pos := Vector2i(width, height)

				#Ignore empty pixels
				if sub_image.get_pixelv(pixel_pos).a < 0.1:
					continue

				image.set_pixelv(initial_pos + pixel_pos, sub_image.get_pixelv(pixel_pos))

	DisplayServer.set_icon(image)


func _on_run_as_gateway_pressed():
	start_gateway()


func _on_run_as_server_pressed():
	start_server()


func _on_run_as_client_pressed():
	start_client()


func _on__map_option_selected(index):
	_map_option_selected = index
