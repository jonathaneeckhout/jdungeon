extends HSlider

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "graphics_fps_limit", 60)
	value_changed.connect(fps_update)
	display_update(value)


func display_update(val: float):
	var fps: int = int(val)
	if fps == max_value:
		textLabel.text = "Unlimited"
	else:
		textLabel.text = str(fps)


func fps_update(newValue: float):
	var fps: int = int(newValue)

	if newValue == max_value:
		Engine.max_fps = 0
	else:
		Engine.max_fps = fps

	display_update(newValue)

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_fps_limit", fps)
