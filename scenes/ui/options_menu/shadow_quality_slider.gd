extends HSlider

const QualityList: Array[String] = ["Lower", "Low", "Medium", "High", "Higher", "Ultra"]

@onready var textLabel: Label = $Label


func _ready() -> void:
	value = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "graphics_shadow_quality", 2
	)
	value_changed.connect(shadow_update)
	shadow_update(value)


func shadow_update(newValue: float):
	var quality: int = newValue

	textLabel.text = QualityList[quality]
	set_shadow_quality(quality)

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_shadow_quality", newValue)


func set_shadow_quality(quality: int):
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/size", 1024 * (quality + 1)
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		1024 * (quality + 1)
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", quality
	)
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", quality
	)
	ProjectSettings.set_setting("rendering/2d/shadow_atlas/size", 512 * (quality + 1))
