extends PanelContainer

signal quit_pressed

@onready var _quit_button: Button = %CloseButton


func _ready() -> void:
	_quit_button.pressed.connect(emit_signal.bind("quit_pressed"))
