extends HSlider

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "volume", max_value)
	value_changed.connect(volume_update)
	display_update(value)


func display_update(val: float):
	textLabel.text = str(val * 100) + "%"


func volume_update(newValue: float):
	var volume: float = linear_to_db(newValue / max_value)

	AudioServer.set_bus_volume_db(0, volume)

	#Save the value from the slider, not the applied volume.
	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "volume", newValue)
	display_update(newValue)
