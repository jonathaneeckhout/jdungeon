extends Control

const GROUPS: Dictionary = {
	"Global": {"color": "WHITE"}, "Local": {"color": "LIGHT_BLUE"}, "Whisper": {"color": "VIOLET"}
}

var current_group: String = "Global"
var username: String = "player"
var wisper_target: String = ""

var delay_timer: Timer

@onready var chat_log: RichTextLabel = $VBoxContainer/Logs/ChatLog
@onready var log_log: RichTextLabel = $VBoxContainer/Logs/LogLog

@onready var input_label: Label = $VBoxContainer/HBoxContainer/Label
@onready var input_field: LineEdit = $VBoxContainer/HBoxContainer/LineEdit


func _ready():
	input_field.text_submitted.connect(_on_text_submitted)
	change_group("Global")
	G.player_rpc.message_received.connect(_on_message_received)

	$VBoxContainer/SelectButtons/ChatButton.pressed.connect(_on_chat_button_pressed)
	$VBoxContainer/SelectButtons/LogsButton.pressed.connect(_on_logs_button_pressed)

	delay_timer = Timer.new()
	delay_timer.name = "DelayTimer"
	delay_timer.one_shot = true
	delay_timer.wait_time = 0.1
	delay_timer.timeout.connect(_on_delay_timer_timeout)
	add_child(delay_timer)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		input_field.grab_focus()
		JUI.chat_active = true
	if event.is_action_pressed("ui_cancel"):
		input_field.release_focus()
		# This timer is needed to prevent race conditions with other ui_cancel listeners
		delay_timer.start()


func change_group(value: String):
	current_group = value

	if current_group == "Whisper" and wisper_target != "":
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
			"Press /g for global chat, /l for local chat and /w <name> to whisper",
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
		if text.length() > 3:
			# Discard the /w part to get the username
			wisper_target = text.replace("/w ", "")
			if wisper_target != "":
				change_group("Whisper")

		input_field.text = ""
		input_field.release_focus()
		JUI.chat_active = false
		return

	if text != "":
		match current_group:
			"Global":
				G.player_rpc.send_message.rpc_id(1, "Global", "", text)
			"Local":
				G.player_rpc.send_message.rpc_id(1, "Local", "", text)
			"Whisper":
				G.player_rpc.send_message.rpc_id(1, "Whisper", wisper_target, text)
			_:
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
		"Whisper":
			append_chat_line_escaped(from, message, GROUPS["Whisper"]["color"])


func append_log_line(message: String, color: String = "YELLOW"):
	log_log.append_text("[color=%s]%s[/color]\n" % [color, escape_bbcode(message)])


func _on_chat_button_pressed():
	chat_log.show()
	log_log.hide()


func _on_logs_button_pressed():
	chat_log.hide()
	log_log.show()


func _on_delay_timer_timeout():
	JUI.chat_active = false
