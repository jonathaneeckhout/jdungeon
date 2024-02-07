extends Control

signal quit_pressed

@onready var _quit_button: Button = $Panel/VBoxContainer/MarginContainer2/CloseButton
@onready var _link_button: Button = $Panel/VBoxContainer/MarginContainer/LinkButton


func _ready() -> void:
	_quit_button.pressed.connect(emit_signal.bind("quit_pressed"))
	_link_button.pressed.connect(_on_link_button_pressed)


func _on_link_button_pressed():
	OS.shell_open("https://github.com/jonathaneeckhout/jdungeon/issues")
