extends TextureButton

@export var sound_on: Texture2D
@export var sound_off: Texture2D

@onready var master_sound = AudioServer.get_bus_index("Master")


func _ready():
	self.pressed.connect(_on_button_pressed)
	if Global.env_audio_mute:
		AudioServer.set_bus_mute(master_sound, true)
	if not AudioServer.is_bus_mute(master_sound):
		self.set_texture_normal(sound_on)
	else:
		self.set_texture_normal(sound_off)


func _on_button_pressed():
	if not AudioServer.is_bus_mute(master_sound):
		AudioServer.set_bus_mute(master_sound, true)
		self.set_texture_normal(sound_off)
	else:
		AudioServer.set_bus_mute(master_sound, false)
		self.set_texture_normal(sound_on)
