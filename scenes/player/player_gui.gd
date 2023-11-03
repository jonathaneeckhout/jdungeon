extends Control

@onready var chatPanel: Control = $ChatPanel


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("j_ui_toggle"):
		visible = !visible
	if event.is_action_pressed("j_ui_chat_toggle"):
		chatPanel.visible = !chatPanel.visible
