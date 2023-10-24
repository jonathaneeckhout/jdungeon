extends Node

var above_ui: bool = false
var chat_active: bool = false


func alertbox(message: String, parent: Node) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Alert"
	dialog.dialog_text = message
	dialog.unresizable = true
	dialog.connect("close_requested", dialog.queue_free)
	parent.add_child(dialog)
	dialog.popup_centered()


func confirmationbox(
	message: String, parent: Node, title: String, confirmed_action: Callable
) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.unresizable = true
	dialog.connect("close_requested", dialog.queue_free)
	dialog.confirmed.connect(confirmed_action)
	parent.add_child(dialog)
	dialog.popup_centered()
