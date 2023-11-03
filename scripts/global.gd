extends Node

var env_run_as_server: bool = false
var env_run_as_client: bool = false
var env_minimize_server_on_start: bool = false

var env_server_address: String = ""
var env_server_port: int = 0
var env_server_max_peers: int = 0
var env_server_crt: String = ""
var env_server_key: String = ""
var env_server_database_backend: String = ""
var env_server_json_backend_file: String = ""
var env_debug: bool = false
var env_audio_mute: bool = false
var env_version_file: String = ""

var env_postgres_address: String = ""
var env_postgres_port: int = 0
var env_postgres_user: String = ""
var env_postgress_password: String = ""
var env_postgress_db: String = ""

var server: Node
var client: Node


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
		J.logger.info(
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
	env_run_as_server = J.env.get_value("RUN_AS_SERVER") == "true"
	env_run_as_client = J.env.get_value("RUN_AS_CLIENT") == "true"
	env_minimize_server_on_start = J.env.get_value("MINIMIZE_SERVER_ON_START") == "true"
	J.logger.info("MINIMIZE_SERVER_ON_START=[%s]" % str(env_minimize_server_on_start))
	return true


func load_server_env_variables() -> bool:
	env_debug = J.env.get_value("DEBUG") == "true"

	J.logger.info("DEBUG=[%s]" % str(env_debug))

	var env_port_str = J.env.get_value("SERVER_PORT")
	if env_port_str == "":
		J.logger.error("Could not load SERVER_PORT env varaible")
		return false

	env_server_port = int(env_port_str)

	J.logger.info("SERVER_PORT=[%d]" % env_server_port)

	var env_max_peers_str = J.env.get_value("SERVER_MAX_PEERS")
	if env_max_peers_str == "":
		J.logger.error("Could not load SERVER_MAX_PEERS env varaible")
		return false

	env_server_max_peers = int(env_max_peers_str)

	J.logger.info("SERVER_MAX_PEERS=[%d]" % env_server_max_peers)

	env_server_crt = J.env.get_value("SERVER_CRT")
	if env_server_crt == "":
		J.logger.error("Could not load SERVER_CRT env varaible")
		return false

	J.logger.info("SERVER_CRT=[%s]" % env_server_crt)

	env_server_key = J.env.get_value("SERVER_KEY")
	if env_server_key == "":
		J.logger.error("Could not load SERVER_KEY env varaible")
		return false

	J.logger.info("SERVER_KEY=[%s]" % env_server_key)

	env_server_database_backend = J.env.get_value("SERVER_DATABASE_BACKEND")
	if env_server_database_backend == "":
		J.logger.error("Could not load SERVER_DATABASE_BACKEND env varaible")
		return false

	J.logger.info("SERVER_DATABASE_BACKEND=[%s]" % env_server_database_backend)

	match env_server_database_backend:
		"json":
			env_server_json_backend_file = J.env.get_value("SERVER_JSON_BACKEND_FILE")
			if env_server_json_backend_file == "":
				J.logger.error("Could not load SERVER_JSON_BACKEND_FILE env varaible")
				return false

			J.logger.info("SERVER_JSON_BACKEND_FILE=[%s]" % env_server_json_backend_file)

		"postgres":
			# REMINDER: DO NOT PRINT CREDENTIAL INFORMATION ABOUT THE DATABASE CONNECTION

			env_postgres_address = J.env.get_value("POSTGRES_ADDRESS")
			if env_postgres_address == "":
				J.logger.error("Could not load POSTGRES_ADDRESS env varaible")
				return false

			var env_postgres_port_str = J.env.get_value("POSTGRES_PORT")
			if env_postgres_port_str == "":
				J.logger.error("Could not load POSTGRES_PORT env varaible")
				return false

			env_postgres_port = int(env_postgres_port_str)

			env_postgres_user = J.env.get_value("POSTGRES_USER")
			if env_postgres_user == "":
				J.logger.error("Could not load POSTGRES_USER env varaible")
				return false

			env_postgress_password = J.env.get_value("POSTGRES_PASSWORD")
			if env_postgress_password == "":
				J.logger.error("Could not load POSTGRES_PASSWORD env varaible")
				return false

			env_postgress_db = J.env.get_value("POSTGRES_DB")
			if env_postgress_db == "":
				J.logger.error("Could not load POSTGRES_DB env varaible")
				return false

	return true


func load_client_env_variables() -> bool:
	env_debug = J.env.get_value("DEBUG") == "true"

	J.logger.info("DEBUG=[%s]" % str(env_debug))

	env_server_address = J.env.get_value("SERVER_ADDRESS")
	if env_server_address == "":
		J.logger.error("Could not load SERVER_ADDRESS env varaible")
		return false

	J.logger.info("SERVER_ADDRESS=[%s]" % env_server_address)

	var env_port_str = J.env.get_value("SERVER_PORT")
	if env_port_str == "":
		J.logger.error("Could not load SERVER_PORT env varaible")
		return false

	env_server_port = int(env_port_str)

	J.logger.info("SERVER_PORT=[%d]" % env_server_port)

	env_audio_mute = J.env.get_value("AUDIO_MUTE") == "true"

	J.logger.info("AUDIO_MUTE=[%s]" % str(env_audio_mute))

	env_version_file = J.env.get_value("VERSION_FILE")

	return true
