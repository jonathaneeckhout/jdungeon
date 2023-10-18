extends Control

const GROUPS: Dictionary = {
	"Global": {"color": "WHITE"}, "Local": {"color": "LIGHT_BLUE"}, "Wisper": {"color": "VIOLET"}
}

var current_group: String = "Global"
var username: String = "player"
var wisper_target: String = ""

@onready var chat_log: RichTextLabel = $VBoxContainer/Logs/ChatLog
@onready var log_log: RichTextLabel = $VBoxContainer/Logs/LogLog

@onready var input_label: Label = $VBoxContainer/HBoxContainer/Label
@onready var input_field: LineEdit = $VBoxContainer/HBoxContainer/LineEdit


func _ready():
	input_field.text_submitted.connect(_on_text_submitted)
	change_group("Global")
	J.rpcs.player.message_received.connect(_on_message_received)

	$VBoxContainer/SelectButtons/ChatButton.pressed.connect(_on_chat_button_pressed)
	$VBoxContainer/SelectButtons/LogsButton.pressed.connect(_on_logs_button_pressed)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		input_field.grab_focus()
		JUI.chat_active = true
	if event.is_action_pressed("ui_cancel"):
		input_field.release_focus()
		JUI.chat_active = false


func change_group(value: String):
	current_group = value

	if current_group == "Wisper" and wisper_target != "":
		input_label.text = "[" + wisper_target + "]"
	else:
		input_label.text = "[" + current_group + "]"

	input_label.set("theme_override_colors/font_color", Color(GROUPS[current_group]["color"]))


func escape_bbcode(bbcode_text: String) -> String:
	# We only need to replace opening brackets to prevent tags from being parsed.
	return bbcode_text.replace("[", "[lb]")


func append_chat_line_escaped(from: String, message: String, color: String = "WHITE"):
	chat_log.append_text(
		"[color=%s]%s: %s[/color]\n" % [color, escape_bbcode(from), escape_bbcode(message)]
	)


func _on_text_submitted(text: String):
	if text == "/h" or text == "/help":
		append_chat_line_escaped(
			"Helper",
			"Press /g for global chat, /l for local chat and /w <name> to wisper",
			"SKY_BLUE"
		)
		input_field.text = ""
		input_field.release_focus()
		JUI.chat_active = false
		return

	if text == "/g":
		change_group("Global")
		input_field.text = ""
		input_field.release_focus()
		JUI.chat_active = false
		return

	if text == "/l":
		change_group("Local")
		input_field.text = ""
		input_field.release_focus()
		JUI.chat_active = false
		return

	if text.begins_with("/w"):
		wisper_target = text.replace("/w ", "")
		if wisper_target != "":
			change_group("Wisper")

		input_field.text = ""
		input_field.release_focus()
		JUI.chat_active = false
		# Discard the /w part to get the username
		return

	if text != "":
		match current_group:
			"Global":
				J.rpcs.player.send_message.rpc_id(1, "Global", "", text)
			"Local":
				J.rpcs.player.send_message.rpc_id(1, "Local", "", text)
			"Wisper":
				J.rpcs.player.send_message.rpc_id(1, "Wisper", wisper_target, text)
			_:
				#TODO: implement other cases
				append_chat_line_escaped(username, text, GROUPS[current_group]["color"])

		# Here you have to send the message to the server
		input_field.text = ""
		input_field.release_focus()
		JUI.chat_active = false


func _on_message_received(type: String, from: String, message: String):
	match type:
		"Global":
			append_chat_line_escaped(from, message, GROUPS["Global"]["color"])
		"Local":
			append_chat_line_escaped(from, message, GROUPS["Local"]["color"])
		"Wisper":
			append_chat_line_escaped(from, message, GROUPS["Wisper"]["color"])


func append_log_line(message: String, color: String = "YELLOW"):
	log_log.append_text("[color=%s]%s[/color]\n" % [color, escape_bbcode(message)])


func _on_chat_button_pressed():
	chat_log.show()
	log_log.hide()


func _on_logs_button_pressed():
	chat_log.hide()
	log_log.show()
