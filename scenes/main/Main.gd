extends Node

const GAME_ICONS: Array[Texture] = [
	preload("res://assets/images/enemies/boar/scaled/example.png"),
	preload("res://assets/images/enemies/flower/scaled/Flower.png"),
	preload("res://assets/images/enemies/moldeddruvar/scaled/moldeddruvar.png"),
	preload("res://assets/images/enemies/sheep/scaled/sheep.png"),
]

const SERVER_SUB_ICON: Texture = preload("res://assets/images/ui/cursors/LootCursor.png")
const GATEWAY_SUB_ICON: Texture = preload("res://assets/images/ui/cursors/TalkCursor.png")

@export var config: ConfigResource = null

## The prefix used for every log line on the client
@export var gateway_logging_prefix: String = "Gateway"

## The prefix used for every log line on the client
@export var server_logging_prefix: String = "Server"

## The prefix used for every log line on the client
@export var client_logging_prefix: String = "Client"

@onready var _gateway_server: WebsocketMultiplayerConnection = %GatewayServer

@onready var _gateway_client: WebsocketMultiplayerConnection = %GatewayClient


# Called when the node enters the scene tree for the first time.
func _ready():
	%RunAsGatewayButton.pressed.connect(_on_run_as_gateway_pressed)
	%RunAsServerButton.pressed.connect(_on_run_as_server_pressed)
	%RunAsClientButton.pressed.connect(_on_run_as_client_pressed)


func _start_gateway():
	GodotLogger._prefix = gateway_logging_prefix

	# Set the window's title
	get_window().title = "JDungeon (Gateway)"

	_set_game_icon(GAME_ICONS.pick_random(), GATEWAY_SUB_ICON)

	GodotLogger.info("Running as Gateway")

	%ServerClient.queue_free()

	%ServerFsm.queue_free()

	%SelectRunMode.queue_free()

	if not _gateway_server.websocket_server_init():
		GodotLogger.error("Failed to init gateway server websocket server")

		get_tree().quit()

		return

	if not _gateway_server.websocket_server_start(
		config.gateway_server_server_port,
		config.gateway_server_server_bind_address,
		config.use_tls,
		config.gateway_server_certh_path,
		config.gateway_server_key_path
	):
		GodotLogger.error("Failed to start gateway server websocket server")

		get_tree().quit()

		return

	if not _gateway_client.websocket_server_init():
		GodotLogger.error("Failed to init gateway client websocket server")

		get_tree().quit()

		return

	if not _gateway_client.websocket_server_start(
		config.gateway_client_server_port,
		config.gateway_client_server_bind_address,
		config.use_tls,
		config.gateway_client_certh_path,
		config.gateway_client_key_path
	):
		GodotLogger.error("Failed to start gateway client websocket server")

		get_tree().quit()

		return

	GodotLogger.info("Gateway successfully started")


func _start_server():
	GodotLogger._prefix = server_logging_prefix

	# Set the window's title
	get_window().title = "JDungeon (Server)"

	_set_game_icon(GAME_ICONS.pick_random(), SERVER_SUB_ICON)

	GodotLogger.info("Running as server")

	%GatewayClient.queue_free()

	%SelectRunMode.queue_free()

	# Register all the scenes so that they can accesses via the J singleton in the rest of the project
	J.register_scenes()

	%ServerFsm.config = config
	# Hardcore this value for now
	%ServerFsm.map_name = "BaseCamp"
	%ServerFsm.start()


func _start_client():
	GodotLogger._prefix = client_logging_prefix

	# Set the window's title
	get_window().title = "JDungeon (Client)"

	_set_game_icon(GAME_ICONS.pick_random())

	GodotLogger.info("Running as client")

	%GatewayServer.queue_free()

	%ServerFsm.queue_free()

	%SelectRunMode.queue_free()

	# Register all the scenes so that they can accesses via the J singleton in the rest of the project
	J.register_scenes()


func _set_game_icon(icon: Texture, sub_icon: Texture = null):
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
	_start_gateway()


func _on_run_as_server_pressed():
	_start_server()


func _on_run_as_client_pressed():
	_start_client()
