extends HSlider

const QualityList: Array[String] = ["Disabled", "x2", "x4", "x8"]

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_antialiasing_msaa", 0
	)
	value_changed.connect(shadow_update)
	shadow_update(value)


func display_update(val: float):
	var quality: int = int(val)
	textLabel.text = QualityList[quality]


func shadow_update(newValue: float):
	var quality: int = int(newValue)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_2d", quality)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", quality)

	LocalSaveSystem.set_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_antialiasing_msaa", newValue
	)
	display_update(newValue)
