extends Node

signal debug_mode_toggled(newStats: bool)

var env_debug: bool = false
var env_network_profiling: bool = false
var env_audio_mute: bool = false
var env_version_file: String = ""
var env_starter_server: String = ""

var env_run_as_gateway: bool = false
var env_run_as_server: bool = false
var env_run_as_client: bool = false
var env_minimize_on_start: bool = false
var env_no_tls: bool = false

var env_gateway_address: String = ""

var env_gateway_client_port: int = 0
var env_gateway_client_max_peers: int = 0
var env_gateway_client_crt: String = ""
var env_gateway_client_key: String = ""

var env_gateway_server_port: int = 0
var env_gateway_server_max_peers: int = 0
var env_gateway_server_crt: String = ""
var env_gateway_server_key: String = ""

var env_server_map: String = ""
var env_server_address: String = ""
var env_server_port: int = 0
var env_server_max_peers: int = 0
var env_server_crt: String = ""
var env_server_key: String = ""

var env_database_backend: String = ""

var env_json_backend_file: String = ""

var env_postgres_address: String = ""
var env_postgres_port: int = 0
var env_postgres_user: String = ""
var env_postgress_password: String = ""
var env_postgress_db: String = ""

var env: GodotEnv

## This is used to increase/reduce output in some classes.
var debug_mode: bool:
	set(val):
		debug_mode = val
		print_debug("Debug mode: " + str(debug_mode))
		debug_mode_toggled.emit(debug_mode)


func _ready():
	#Do not listen to inputs in non-debug builds, for performance reasons.
	set_process_unhandled_input(OS.is_debug_build())

	env = GodotEnv.new()

	load_common_env_variables()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_mode_toggle"):
		debug_mode = !debug_mode


func load_local_settings():
	#Load or create the file if it doesn't exist.
	if not LocalSaveSystem.file_exists():
		LocalSaveSystem.save_file()
	LocalSaveSystem.load_file()

	#Load translations
	if not DirAccess.dir_exists_absolute("user://translations/"):
		print_debug(DirAccess.make_dir_absolute("user://translations/"))

	var foundTranslations: Array[String] = []

	for fileName in DirAccess.get_files_at("user://translations/"):
		if fileName.get_extension() == "translation":
			foundTranslations.append(fileName.get_basename())
			TranslationServer.add_translation(load("user://translations/" + fileName))

	if not foundTranslations.is_empty():
		GodotLogger.info(
			"Found {0} translation/s. {1}".format(
				[foundTranslations.size(), str(foundTranslations)]
			)
		)

	#Volume
	var volume: float = linear_to_db(
		LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "volume", 1 as float)
	)
	AudioServer.set_bus_volume_db(0, volume)

	#Fullscreen
	var fullScreen: bool = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_fullscreen", false
	)
	if fullScreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	#FPS
	var fps: int = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_fps_limit", 60 as int
	)
	Engine.max_fps = fps

	#Shadow quality
	var shadows: int = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_shadow_quality", 2 as int
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/size", 1024 * (shadows + 1)
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		1024 * (shadows + 1)
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", shadows
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", shadows
	)
	ProjectSettings.set_setting("rendering/2d/shadow_atlas/size", 512 * (shadows + 1))

	#Half illumination resolution
	var halfIllumination: bool = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_global_illumination_halved", false
	)
	RenderingServer.gi_set_use_half_resolution(halfIllumination)

	#Antialiasing
	var antiAliasing: int = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_antialiasing_msaa", 0 as int
	)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_2d", antiAliasing)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", antiAliasing)

	#Language
	var locale: String = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "language_locale", "en"
	)
	TranslationServer.set_locale(locale)

	#VSync
	var vSync: int = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_vsync_mode", 1 as int
	)
	DisplayServer.window_set_vsync_mode(vSync)

	#Set controls
	InputRemapping.load_mappings()

	#The colorblindness filter does not need any specific setters, the filters read directly from the loaded SaveFile.ini


func load_common_env_variables() -> bool:
	env_debug = env.get_value("DEBUG") == "true"

	GodotLogger.info("DEBUG=[%s]" % str(env_debug))

	env_network_profiling = env.get_value("NETWORK_PROFILING") == "true"

	GodotLogger.info("NETWORK_PROFILING=[%s]" % str(env_network_profiling))

	env_run_as_gateway = env.get_value("RUN_AS_GATEWAY") == "true"
	env_run_as_server = env.get_value("RUN_AS_SERVER") == "true"
	env_run_as_client = env.get_value("RUN_AS_CLIENT") == "true"

	env_minimize_on_start = env.get_value("MINIMIZE_ON_START") == "true"
	GodotLogger.info("MINIMIZE_ON_START=[%s]" % str(env_minimize_on_start))

	env_no_tls = env.get_value("NO_TLS") == "true"
	GodotLogger.info("NO_TLS=[%s]" % str(env_no_tls))

	return true


func load_database_env_variables() -> bool:
	env_database_backend = env.get_value("DATABASE_BACKEND")
	if env_database_backend == "":
		GodotLogger.error("Could not load DATABASE_BACKEND env varaible")
		return false

	GodotLogger.info("DATABASE_BACKEND=[%s]" % env_database_backend)

	match env_database_backend:
		"json":
			env_json_backend_file = env.get_value("JSON_BACKEND_FILE")
			if env_json_backend_file == "":
				GodotLogger.error("Could not load JSON_BACKEND_FILE env varaible")
				return false

			GodotLogger.info("JSON_BACKEND_FILE=[%s]" % env_json_backend_file)

		"postgres":
			# REMINDER: DO NOT PRINT CREDENTIAL INFORMATION ABOUT THE DATABASE CONNECTION

			env_postgres_address = env.get_value("POSTGRES_ADDRESS")
			if env_postgres_address == "":
				GodotLogger.error("Could not load POSTGRES_ADDRESS env varaible")
				return false

			var env_postgres_port_str = env.get_value("POSTGRES_PORT")
			if env_postgres_port_str == "":
				GodotLogger.error("Could not load POSTGRES_PORT env varaible")
				return false

			env_postgres_port = int(env_postgres_port_str)

			env_postgres_user = env.get_value("POSTGRES_USER")
			if env_postgres_user == "":
				GodotLogger.error("Could not load POSTGRES_USER env varaible")
				return false

			env_postgress_password = env.get_value("POSTGRES_PASSWORD")
			if env_postgress_password == "":
				GodotLogger.error("Could not load POSTGRES_PASSWORD env varaible")
				return false

			env_postgress_db = env.get_value("POSTGRES_DB")
			if env_postgress_db == "":
				GodotLogger.error("Could not load POSTGRES_DB env varaible")
				return false
	return true


func load_gateway_env_variables() -> bool:
	var env_client_port_str = env.get_value("GATEWAY_CLIENT_PORT")
	if env_client_port_str == "":
		GodotLogger.error("Could not load GATEWAY_CLIENT_PORT env varaible")
		return false

	env_gateway_client_port = int(env_client_port_str)

	GodotLogger.info("GATEWAY_CLIENT_PORT=[%d]" % env_gateway_client_port)

	var env_client_max_peers_str = env.get_value("GATEWAY_CLIENT_MAX_PEERS")
	if env_client_max_peers_str == "":
		GodotLogger.error("Could not load GATEWAY_CLIENT_MAX_PEERS env varaible")
		return false

	env_gateway_client_max_peers = int(env_client_max_peers_str)

	GodotLogger.info("GATEWAY_CLIENT_MAX_PEERS=[%d]" % env_gateway_client_max_peers)

	env_gateway_client_crt = env.get_value("GATEWAY_CLIENT_CRT")
	if env_gateway_client_crt == "":
		GodotLogger.error("Could not load GATEWAY_CLIENT_CRT env varaible")
		return false

	GodotLogger.info("GATEWAY_CLIENT_CRT=[%s]" % env_gateway_client_crt)

	env_gateway_client_key = env.get_value("GATEWAY_CLIENT_KEY")
	if env_gateway_client_key == "":
		GodotLogger.error("Could not load GATEWAY_CLIENT_KEY env varaible")
		return false

	GodotLogger.info("GATEWAY_CLIENT_KEY=[%s]" % env_gateway_client_key)

	var env_server_port_str = env.get_value("GATEWAY_SERVER_PORT")
	if env_server_port_str == "":
		GodotLogger.error("Could not load GATEWAY_SERVER_PORT env varaible")
		return false

	env_gateway_server_port = int(env_server_port_str)

	GodotLogger.info("GATEWAY_SERVER_PORT=[%d]" % env_gateway_server_port)

	var env_server_max_peers_str = env.get_value("GATEWAY_SERVER_MAX_PEERS")
	if env_server_max_peers_str == "":
		GodotLogger.error("Could not load GATEWAY_SERVER_MAX_PEERS env varaible")
		return false

	env_gateway_server_max_peers = int(env_server_max_peers_str)

	GodotLogger.info("GATEWAY_SERVER_MAX_PEERS=[%d]" % env_gateway_server_max_peers)

	env_gateway_server_crt = env.get_value("GATEWAY_SERVER_CRT")
	if env_gateway_server_crt == "":
		GodotLogger.error("Could not load GATEWAY_SERVER_CRT env varaible")
		return false

	GodotLogger.info("GATEWAY_SERVER_CRT=[%s]" % env_gateway_server_crt)

	env_gateway_server_key = env.get_value("GATEWAY_SERVER_KEY")
	if env_gateway_server_key == "":
		GodotLogger.error("Could not load GATEWAY_SERVER_KEY env varaible")
		return false

	GodotLogger.info("GATEWAY_SERVER_KEY=[%s]" % env_gateway_server_key)

	env_starter_server = env.get_value("STARTER_SERVER")
	if env_starter_server == "":
		GodotLogger.error("Could not load STARTER_SERVER env varaible")
		return false

	return load_database_env_variables()


func load_server_env_variables() -> bool:
	env_gateway_address = env.get_value("GATEWAY_ADDRESS")
	if env_gateway_address == "":
		GodotLogger.error("Could not load GATEWAY_ADDRESS env varaible")
		return false

	GodotLogger.info("GATEWAY_ADDRESS=[%s]" % env_gateway_address)

	var env_gateway_port_str = env.get_value("GATEWAY_SERVER_PORT")
	if env_gateway_port_str == "":
		GodotLogger.error("Could not load GATEWAY_SERVER_PORT env varaible")
		return false

	env_gateway_server_port = int(env_gateway_port_str)

	GodotLogger.info("GATEWAY_SERVER_PORT=[%d]" % env_gateway_server_port)

	env_server_address = env.get_value("SERVER_ADDRESS")
	if env_server_address == "":
		GodotLogger.error("Could not load SERVER_ADDRESS env varaible")
		return false

	GodotLogger.info("SERVER_ADDRESS=[%s]" % env_server_address)

	env_server_map = env.get_value("SERVER_MAP")
	if env_server_map == "":
		GodotLogger.info("Could not load SERVER_MAP env varaible")
	else:
		GodotLogger.info("SERVER_MAP=[%s]" % env_server_map)

	var env_port_str = env.get_value("SERVER_PORT")
	if env_port_str == "":
		GodotLogger.error("Could not load SERVER_PORT env varaible")
		return false

	env_server_port = int(env_port_str)

	GodotLogger.info("SERVER_PORT=[%d]" % env_server_port)

	var env_max_peers_str = env.get_value("SERVER_MAX_PEERS")
	if env_max_peers_str == "":
		GodotLogger.error("Could not load SERVER_MAX_PEERS env varaible")
		return false

	env_server_max_peers = int(env_max_peers_str)

	GodotLogger.info("SERVER_MAX_PEERS=[%d]" % env_server_max_peers)

	env_server_crt = env.get_value("SERVER_CRT")
	if env_server_crt == "":
		GodotLogger.error("Could not load SERVER_CRT env varaible")
		return false

	GodotLogger.info("SERVER_CRT=[%s]" % env_server_crt)

	env_server_key = env.get_value("SERVER_KEY")
	if env_server_key == "":
		GodotLogger.error("Could not load SERVER_KEY env varaible")
		return false

	GodotLogger.info("SERVER_KEY=[%s]" % env_server_key)

	return load_database_env_variables()


func load_client_env_variables() -> bool:
	env_gateway_address = env.get_value("GATEWAY_ADDRESS")
	if env_gateway_address == "":
		GodotLogger.error("Could not load GATEWAY_ADDRESS env varaible")
		return false

	GodotLogger.info("GATEWAY_ADDRESS=[%s]" % env_gateway_address)

	var env_port_str = env.get_value("GATEWAY_CLIENT_PORT")
	if env_port_str == "":
		GodotLogger.error("Could not load GATEWAY_CLIENT_PORT env varaible")
		return false

	env_gateway_client_port = int(env_port_str)

	GodotLogger.info("GATEWAY_CLIENT_PORT=[%d]" % env_gateway_client_port)

	env_audio_mute = env.get_value("AUDIO_MUTE") == "true"

	GodotLogger.info("AUDIO_MUTE=[%s]" % str(env_audio_mute))

	env_version_file = env.get_value("VERSION_FILE")

	return true
