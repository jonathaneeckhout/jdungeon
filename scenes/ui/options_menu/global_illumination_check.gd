extends CheckBox

func _ready() -> void:
	button_pressed = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "graphics_global_illumination_halved", false)
	toggled.connect(illumination_update)
	illumination_update(button_pressed)
	

func illumination_update(halve: bool):
	ProjectSettings.set_setting("rendering/global_illumination/gi/use_half_resolution", halve)
	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_global_illumination_halved", halve)


	
	
	
