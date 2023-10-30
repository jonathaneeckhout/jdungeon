extends OptionButton

const VSyncSettings: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]


func _init() -> void:
	assert(VSyncSettings.size() == 4)
	for setting in VSyncSettings:
		add_item(setting)


func _ready() -> void:
	var setting: int = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_vsync_mode", 1
	)
	item_selected.connect(vsync_update)
	vsync_update(setting)


func vsync_update(id: int):
	text = str(VSyncSettings[id])
	selected = id

	DisplayServer.window_set_vsync_mode(id)

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_vsync_mode", id)
