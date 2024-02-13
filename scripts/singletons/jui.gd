extends Node

var above_ui: bool = false
var chat_active: bool = false

var dialog: AcceptDialog = null


func alertbox(message: String, parent: Node) -> void:
	if dialog != null:
		dialog.queue_free()

	dialog = AcceptDialog.new()
	dialog.title = "Alert"
	dialog.dialog_text = message
	dialog.unresizable = true
	dialog.connect("close_requested", dialog.queue_free)
	parent.add_child(dialog)
	dialog.popup_centered()


func confirmationbox(
	message: String, parent: Node, title: String, confirmed_action: Callable
) -> void:
	if dialog != null:
		dialog.queue_free()

	dialog = ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.unresizable = true
	dialog.connect("close_requested", dialog.queue_free)
	dialog.confirmed.connect(confirmed_action)
	parent.add_child(dialog)
	dialog.popup_centered()


func clear_dialog() -> void:
	if dialog != null:
		dialog.queue_free()
