extends HSlider

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "tooltip_delay", 0.2)
	value_changed.connect(delay_update)
	display_update(value)


func display_update(val: float):
	textLabel.text = str(val)


func delay_update(newValue: float):
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", value)
	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "tooltip_delay", newValue)
	display_update(newValue)
