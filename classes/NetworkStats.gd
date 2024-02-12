extends Node

class_name NetworkStats

var _function_calls: Dictionary = {}


func log_func_call(func_name: String, caller: String):
	if _function_calls.has(func_name):
		_function_calls[func_name]["total"] += 1
		if _function_calls[func_name]["callers"].has(caller):
			_function_calls[func_name]["callers"][caller] += 1
		else:
			_function_calls[func_name]["callers"][caller] = 1

	else:
		_function_calls[func_name] = {"total": 1, "callers": {caller: 1}}
