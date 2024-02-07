extends Control

class_name LoginPanel

signal login_pressed(username: String, password: String)
signal create_account_pressed(username: String, password: String)
signal show_create_account_pressed
signal back_create_account_pressed

#LoginContainer
@onready var login_container := $Panel/LoginContainer
@onready var login_input := $Panel/LoginContainer/MarginContainer/VBoxContainer/LoginText
@onready
var login_password_input := $Panel/LoginContainer/MarginContainer2/VBoxContainer/LoginPasswordText
@onready var login_button := $Panel/LoginContainer/MarginContainer3/VBoxContainer/LoginButton
@onready
var goto_create_account_button := $Panel/LoginContainer/MarginContainer3/VBoxContainer/GoToCreateAccountButton

#CreateAccountContainer
@onready var create_account_container := $Panel/CreateAccountContainer

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

@onready var _anim_player := $AnimationPlayer


func _ready():
	login_button.pressed.connect(_on_login_button_pressed)
	goto_create_account_button.pressed.connect(_on_show_create_account_menu)
	create_account_button.pressed.connect(_on_create_account_button_pressed)
	goto_login_button.pressed.connect(_on_back_create_account_button_pressed)

	login_input.grab_focus.call_deferred()

	login_container.show()


func _input(event):
	if login_container.is_visible_in_tree():
		if event.is_action_pressed("ui_accept"):
			login_button.emit_signal("pressed")

	if create_account_container.is_visible_in_tree():
		if event.is_action_pressed("ui_accept"):
			create_account_button.emit_signal("pressed")


func show_create_account_container():
	self.show()
	_anim_player.play("goto_createaccount")
	register_login_input.grab_focus.call_deferred()


func show_login_container():
	self.show()
	_anim_player.play("goto_login")
	login_input.grab_focus.call_deferred()


func _on_login_button_pressed():
	var username = login_input.text
	var password = login_password_input.text

	if username == "" or password == "":
		JUI.alertbox("Invalid username or password", self)
		GodotLogger.warn("Invalid username or password")
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
		GodotLogger.warn("Invalid username or password")
		return

	if password != repeat_password:
		JUI.alertbox("Password mismatch", self)
		GodotLogger.warn("Password mismatch")
		return

	create_account_pressed.emit(username, password)


func _on_back_create_account_button_pressed():
	back_create_account_pressed.emit()
