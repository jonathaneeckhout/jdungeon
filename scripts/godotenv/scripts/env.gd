# GodotEnv Singleton
# Author: Nik Mirza
# Email: nik96mirza[at]gmail.com
extends Node


func get_value(valuename: String):
	# prioritized os environment variable
	if OS.has_environment(valuename):
		J.logger.info("Getting environment value=[%s]" % valuename)
		return OS.get_environment(valuename)

	var env:Dictionary = parse("res://.env")
	if env.has(valuename):
		J.logger.info("Getting environment value=[%s]" % valuename)
		return env[valuename]

	J.logger.warn("Could not find environment value=[%s]" % valuename)
	# return empty
	return ""


func parse(filename:String):
	if !FileAccess.file_exists(filename):
		J.logger.warn("File=[%s] does not exist" % filename)
		return {}

	var file:FileAccess = FileAccess.open(filename, FileAccess.READ)

	var env:Dictionary = {}
	var line:String = ""

	while !file.eof_reached():
		line = file.get_line()
		var o:PackedStringArray = line.split("=")

		if o.size() == 2:  # only check valid lines
			env[o[0]] = o[1].lstrip('"').rstrip('"')

	return env
