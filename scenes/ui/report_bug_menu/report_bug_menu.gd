extends Control

signal quit_pressed

@onready var quitBtn: Button = $Panel/VBoxContainer/MarginContainer2/CloseButton
@onready var linkBtn: Button = $Panel/VBoxContainer/MarginContainer/LinkButton


func _ready() -> void:
	quitBtn.pressed.connect(emit_signal.bind("quit_pressed"))
	linkBtn.pressed.connect(_on_link_button_pressed)


func _on_link_button_pressed():
	OS.shell_open("https://github.com/jonathaneeckhout/jdungeon/issues")
