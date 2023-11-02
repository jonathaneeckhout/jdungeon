extends CheckBox


func _ready() -> void:
	button_pressed = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_global_illumination_halved", false
	)
	toggled.connect(illumination_update)


func illumination_update(halved: bool):
	RenderingServer.gi_set_use_half_resolution(halved)
	LocalSaveSystem.set_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_global_illumination_halvedd", halved
	)
