extends CheckBox


func _ready() -> void:
	button_pressed = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_fullscreen", false
	)
	toggled.connect(fullscreen_update)


func fullscreen_update(full: bool):
	if full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_fullscreen", full)
