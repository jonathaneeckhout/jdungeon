extends Control

class_name DisclaimerPanel

signal accepted


# Called when the node enters the scene tree for the first time.
func _ready():
	$Panel/ConnectContainer/MarginContainer3/AgreeButton.pressed.connect(_on_accept)


func _on_accept():
	self.hide()
	accepted.emit()
