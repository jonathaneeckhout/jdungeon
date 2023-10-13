extends HSlider

func _ready() -> void:
	value = max_value * 0.5
	volume_update(value)
	value_changed.connect(volume_update)
	
func volume_update(newValue:float):
	var volume:float = linear_to_db(newValue / max_value)
	
	AudioServer.set_bus_volume_db(0, volume)

