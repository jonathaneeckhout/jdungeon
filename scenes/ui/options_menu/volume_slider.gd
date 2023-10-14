extends HSlider

func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "volume", max_value)
	value_changed.connect(volume_update)
	
func volume_update(newValue:float):
	var volume:float = linear_to_db(newValue / max_value)
	
	AudioServer.set_bus_volume_db(0, volume)
	
	#Save the value from the slider, not the applied volume.
	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "volume", newValue)

