extends Button


func _pressed() -> void:
	OS.shell_open("file://" + OS.get_user_data_dir())
