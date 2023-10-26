extends Control

@export var login_panel: Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Panel/ConnectContainer/MarginContainer3/AgreeButton.pressed.connect(_on_accept)


func _on_accept():
	self.hide()
	login_panel.show()
