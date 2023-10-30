extends HSlider

const VSyncSettings: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]

@onready var textLabel:Label = $Label

func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "graphics_vsync_mode", 1)
	value_changed.connect(vsync_update)
	vsync_update(value)
	

func vsync_update(newValue: float):
	var setting: int = newValue
	textLabel.text = str(VSyncSettings[setting])
	
	DisplayServer.window_set_vsync_mode(setting)

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_vsync_mode", setting)
	
