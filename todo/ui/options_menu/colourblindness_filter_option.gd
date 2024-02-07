extends OptionButton
## This setting is used by "res://assets/shaders/colorblindness_assistance_material.gd"

const FilterSettings: Array[String] = ["Disabled", "Deutranopia", "Protanopia", "Tritanopia"]


func _init() -> void:
	#There must be as many settings as there are Shaders
	assert(ShaderMaterialColorblindnessAssist.Shaders.size() == FilterSettings.size())
	for setting in FilterSettings:
		add_item(setting)


func _ready() -> void:
	var setting: int = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "accessibility_colourblindness_filter", 0
	)
	item_selected.connect(filter_update)
	display_update(setting)


func display_update(id: int):
	text = str(FilterSettings[id])
	selected = id


func filter_update(id: int):
	LocalSaveSystem.set_data(
		LocalSaveSystem.Sections.SETTINGS, "accessibility_colourblindness_filter", id
	)
	display_update(id)
