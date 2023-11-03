extends ShaderMaterial
class_name ShaderMaterialColorblindnessAssist
## Uses the "accessibility_colorblindness_filter" setting to automatically load the proper filter when initialized
## Apply this material with "material = ShaderMaterialColorblindnessAssist.new()" 
## Or trough the inspector by clicking in the "material" property.


const Shaders: Array[Shader] = [
	null,
	preload("res://assets/shaders/deutranopia_colorblindness_by_Vildravn.gdshader"),
	preload("res://assets/shaders/protanopia_colorblindness_by_Vildravn.gdshader"),
	preload("res://assets/shaders/tritanopia_colorblindness_by_Vildravn.gdshader")
]

func _init() -> void:
	var shaderMode: int = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "accessibility_colorblindness_filter", 0)
	shader = Shaders[shaderMode]
