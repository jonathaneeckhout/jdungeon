# GodotEnv Singleton
# Author: Nik Mirza
# Email: nik96mirza[at]gmail.com
extends Node


func get_value(valuename: String):
	# prioritized os environment variable
	if OS.has_environment(valuename):
		Gmf.logger.info("Getting environment value=[%s]" % valuename)
		return OS.get_environment(valuename)

	var env = parse("res://.env")
	if env.has(valuename):
		Gmf.logger.info("Getting environment value=[%s]" % valuename)
		return env[valuename]

	Gmf.logger.warn("Could not find environment value=[%s]" % valuename)
	# return empty
	return ""


func parse(filename):
	if !FileAccess.file_exists(filename):
		Gmf.logger.warn("File=[%s] does not exist" % filename)
		return {}

	var file = FileAccess.open(filename, FileAccess.READ)

	var env = {}
	var line = ""

	while !file.eof_reached():
		line = file.get_line()
		var o = line.split("=")

		if o.size() == 2:  # only check valid lines
			env[o[0]] = o[1].lstrip('"').rstrip('"')

	return env
