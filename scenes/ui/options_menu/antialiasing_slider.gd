extends HSlider

const QualityList: Array[String] = ["Disabled", "x2", "x4", "x8"]

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_antialiasing_msaa", 0
	)
	value_changed.connect(shadow_update)
	shadow_update(value)


func shadow_update(newValue: float):
	var quality: int = newValue

	textLabel.text = QualityList[quality]
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_2d", quality)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", quality)

	LocalSaveSystem.set_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_antialiasing_msaa", newValue
	)
