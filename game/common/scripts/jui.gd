class_name jui
extends Node

func alertbox(message: String, parent: Node) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Alert"
	dialog.dialog_text = message
	dialog.unresizable = true
	dialog.connect("close_requested", dialog.queue_free)
	parent.add_child(dialog)
	dialog.popup_centered()
