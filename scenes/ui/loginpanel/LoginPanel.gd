extends Control

signal connect_pressed(address: String, port: int)
signal login_pressed(username: String, password: String)
signal create_account_pressed(username: String, password: String)
signal show_create_account_pressed
signal back_create_account_pressed

# ConnectContainer
@onready
var server_address_input := $Panel/ConnectContainer/MarginContainer/VBoxContainer/ServerAddressText
@onready
var server_port_input := $Panel/ConnectContainer/MarginContainer2/VBoxContainer/ServerPortText
@onready var connect_button := $Panel/ConnectContainer/MarginContainer3/ConnectButton

#LoginContainer
@onready var login_container := $Panel/LoginContainer
@onready var login_input := $Panel/LoginContainer/MarginContainer/VBoxContainer/LoginText
@onready
var login_password_input := $Panel/LoginContainer/MarginContainer2/VBoxContainer/LoginPasswordText
@onready var login_button := $Panel/LoginContainer/MarginContainer3/VBoxContainer/LoginButton
@onready
var goto_create_account_button := $Panel/LoginContainer/MarginContainer3/VBoxContainer/GoToCreateAccountButton

#CreateAccountContainer
@onready
var register_login_input := $Panel/CreateAccountContainer/MarginContainer/VBoxContainer/LoginText
@onready
var register_password_input := $Panel/CreateAccountContainer/MarginContainer2/VBoxContainer/PasswordText
@onready
var register_password_confirm_input := $Panel/CreateAccountContainer/MarginContainer2/VBoxContainer/PasswordConfirmText
@onready
var create_account_button := $Panel/CreateAccountContainer/MarginContainer3/VBoxContainer/CreateAccountButton
@onready
var goto_login_button := $Panel/CreateAccountContainer/MarginContainer3/VBoxContainer/BackToLoginButton

#AudioStreamers
@onready var click_audio_stream_player := $ClickAudioStreamPlayer
@onready var background_audio_stream_player := $BackgroundAudioStreamPlayer

@onready var _anim_player := $AnimationPlayer


func _ready():	
	server_address_input.text = J.global.env_server_address
	server_port_input.text = str(J.global.env_server_port)
	connect_button.pressed.connect(_on_connect_button_pressed)
	login_button.pressed.connect(_on_login_button_pressed)
	goto_create_account_button.pressed.connect(_on_show_create_account_menu)
	create_account_button.pressed.connect(_on_create_account_button_pressed)
	goto_login_button.pressed.connect(_on_back_create_account_button_pressed)

	if not J.is_server():
		background_audio_stream_player.play()
		background_audio_stream_player.finished.connect(background_audio_stream_player.play)
		server_address_input.grab_focus.call_deferred()
		
	var buttons: Array = get_tree().get_nodes_in_group("ui_button")
	for button in buttons:
		button.pressed.connect(_on_button_pressed)
		
		
	

func _input(event):
	if login_container.is_visible_in_tree():
		if event.is_action_pressed("ui_accept"):
			login_button.emit_signal("pressed")


func show_connect_container():
	self.show()
	_anim_player.play("goto_connect")
	server_address_input.grab_focus.call_deferred()
	


func show_create_account_container():
	self.show()
	_anim_player.play("goto_createaccount")
	register_login_input.grab_focus.call_deferred()
	


func show_login_container():
	self.show()
	_anim_player.play("goto_login")
	login_input.grab_focus.call_deferred()


func _on_connect_button_pressed():
	var server_address = server_address_input.text
	var server_port = int(server_port_input.text)
	if server_address == "" or server_port <= 0:
		JUI.alertbox("Invalid server address or port", self)
	connect_pressed.emit(server_address, server_port)


func _on_login_button_pressed():
	var username = login_input.text
	var password = login_password_input.text

	if username == "" or password == "":
		JUI.alertbox("Invalid username or password", self)
		J.logger.warn("Invalid username or password")
		return

	login_pressed.emit(username, password)


func _on_show_create_account_menu():
	show_create_account_pressed.emit()


func _on_create_account_button_pressed():
	var username = register_login_input.text
	var password = register_password_input.text
	var repeat_password = register_password_confirm_input.text

	if username == "" or password == "" or repeat_password == "":
		JUI.alertbox("Fill in all fields", self)
		J.logger.warn("Invalid username or password")
		return

	if password != repeat_password:
		JUI.alertbox("Password mismatch", self)
		J.logger.warn("Password mismatch")
		return

	create_account_pressed.emit(username, password)


func _on_back_create_account_button_pressed():
	back_create_account_pressed.emit()


func _on_button_pressed():
	click_audio_stream_player.play()


func stop_login_background_audio():
	background_audio_stream_player.stop()
