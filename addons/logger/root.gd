@tool
extends EditorPlugin

var loadSingletonPlugin = {
	"GodotLogger" : "res://addons/logger/logger.gd",
}

func _enter_tree():
	for names in loadSingletonPlugin.keys():
		add_autoload_singleton(names, loadSingletonPlugin[names])


func _exit_tree():
	for names in loadSingletonPlugin.keys():
		remove_autoload_singleton(names)
