extends HSlider

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "tooltip_delay", 0.2)
	value_changed.connect(delay_update)
	delay_update(value)


func delay_update(newValue: float):
	textLabel.text = str(newValue)
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", value)

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "tooltip_delay", newValue)
