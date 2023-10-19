extends Control

signal quit_pressed

@onready var quitBtn: Button = $QuitButton


func _ready() -> void:
	quitBtn.pressed.connect(emit_signal.bind("quit_pressed"))
