extends HSlider

@onready var textLabel:Label = $Label

func _ready() -> void:
	value = LocalSaveSystem.get_data(LocalSaveSystem.Sections.SETTINGS, "graphics_fps_limit", 60)
	value_changed.connect(fps_update)
	fps_update(value)
	

func fps_update(newValue: float):
	var fps: int = int(newValue)
	textLabel.text = str(fps)
	
	Engine.max_fps = fps

	LocalSaveSystem.set_data(LocalSaveSystem.Sections.SETTINGS, "graphics_fps_limit", fps)
	
