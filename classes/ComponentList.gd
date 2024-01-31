extends RefCounted

class_name ComponentList

var _component_list: Dictionary = {}


func register_component(component_name: String, component: Node) -> bool:
	if _component_list.has(component_name):
		GodotLogger.warn("Component=[%s] already registered" % component_name)

		return false

	_component_list[component_name] = component

	GodotLogger.info("Component=[%s] successfully registered" % component_name)

	return true


func get_component(component_name: String) -> Node:
	if not _component_list.has(component_name):
		GodotLogger.warn("Can not get Component=[%s]" % component_name)

		return null

	return _component_list[component_name]
