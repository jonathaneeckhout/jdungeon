extends Node
class_name ProgressFlagSystem

const SAVE_DIRECTORY_SERVER: String = "res://ProgressFlags/"
const SAVE_DIRECTORY_CLIENT: String = "res://ProgressFlags/"
const BACKUP_SUB_DIRECTORY: String = "backup/"

var flagDictionary: Dictionary

func _init() -> void:
	if G.is_server():
		DirAccess.make_dir_recursive_absolute(get_directory(false))
		DirAccess.make_dir_recursive_absolute(get_directory(true))
	else:
		DirAccess.make_dir_recursive_absolute(get_directory(false))
		DirAccess.make_dir_recursive_absolute(get_directory(true))
		

func get_directory(backup: bool) -> String:
	var output: String
	if G.is_server():
		output = SAVE_DIRECTORY_SERVER
	else: 
		output = SAVE_DIRECTORY_CLIENT
	if backup:
		output += BACKUP_SUB_DIRECTORY	
	return output


func get_path_to_file(user: String, backup: bool):
	if backup:
		# This ensures that the backup does not overwrite any existing user names.
		# Non-backup names should not be using this, since active usernames cannot repeat.
		var initialFileName: String = get_directory(true) + user
		var currentFileName: String = initialFileName
		var count:int = 1
		
		#If a file with this name exists
		while FileAccess.file_exists(currentFileName):	
			#Add a number at the end and try again
			currentFileName = initialFileName + str(count)
			
		#Once a non-used filename is found, return it
		return currentFileName
	else:
		return get_directory(false) + user


## Prepares the Dictionary for the given user, forceOverwrite will replace any existing user's data with the new one.
## But a backup will be made beforehand.
func register_user(user: String, forceOverwrite: bool):
	#If the user does not exist, simply register it.
	if not is_user_registered(user):
		flagDictionary[user] = {}
		save_user_flags(user, false)
		return
	
	#If it does but it is set to overwrite, make a backup and replace.
	if is_user_registered(user) and forceOverwrite:
		GodotLogger.info("Overwritting user '{0}' data, backup in progress.")
		#Ensure the save succeeded before overwriting
		if save_user_flags(user, true):
			flagDictionary[user] = {}
			GodotLogger.info("User '{0}' registered successfully.".format([user]))
		else:
			GodotLogger.error(
				"Failed to create backup, the new user could not be registered."
				)
		

func set_user_flag(user: String, flagName: String, activate: bool):
	if not is_user_loaded(user):
		GodotLogger.error(
			"User '{0}' is not loaded. Exists = {1}".format([user, str(is_user_registered(user))])
		)
		return
	
	flagDictionary[user][flagName] = activate
	
func get_user_flag_state(user: String, flagName: String) -> bool:
	return flagDictionary[user].get(flagName, false)

func get_user_flags(user: String) -> Dictionary:
	return flagDictionary[user]

func save_user_flags(user: String, backup: bool) -> bool:
	if not is_user_loaded(user):
		GodotLogger.error("User '{0}' does not exist, cannot save.")
		return false
	
	
	var pathToFile: String = get_path_to_file(user, backup)
	var file := FileAccess.open(pathToFile, FileAccess.WRITE_READ)
	
	if backup:
		GodotLogger.info(
			"Creating backup for user '{0}' with path '{1}'".format([user, pathToFile])
		)
	
	#Failed to open
	if file == null:
		var openError: Error = FileAccess.get_open_error()
		GodotLogger.error(
			"Could not open/create file '{0}', failed with error {1} ({2})".format([pathToFile, openError, error_string(openError)])
			)
		return false
	
	var stringData: String = JSON.stringify(flagDictionary[user], "    ")
	file.store_string(stringData)
	file.close()

	return true

func load_user_flags(user: String) -> bool:
	var pathToFile: String = get_path_to_file(user, false)
	var file := FileAccess.open(pathToFile, FileAccess.READ)
	
	if file == null:
		var openError: Error = FileAccess.get_open_error()
		GodotLogger.error(
			"Could not open/create file '{0}', failed with error {1} ({2})".format([pathToFile, openError, error_string(openError)])
			)
		return false

	var string_data: String = file.get_as_text()
	var flagsLoaded = JSON.parse_string(string_data)
	
	if flagsLoaded is Dictionary:
		flagDictionary[user] = flagsLoaded
		if Global.debug_mode:
			GodotLogger.info(
				"Loaded flags for user '{0}'.".format([user])
			)
		return true
	else:
		GodotLogger.error(
			"The retrieved data from file '{0}' is not a Dictionary".format([pathToFile])
			)
		return false
	

func is_user_loaded(user: String) -> bool:
	return flagDictionary.has(user)

func is_user_registered(user: String) -> bool:
	return FileAccess.file_exists(get_path_to_file(user, false))
	
