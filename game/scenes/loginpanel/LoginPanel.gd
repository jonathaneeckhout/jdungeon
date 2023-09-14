extends Control

signal connect_pressed(address: String, port: int)
signal login_pressed(username: String, password: String)
signal create_account_pressed(username: String, password: String)
signal show_create_account_pressed
signal back_create_account_pressed


func _ready():
	$Panel/ConnectContainer/ServerAddressText.text = Gmf.global.env_server_address
	$Panel/ConnectContainer/ServerPortText.text = str(Gmf.global.env_server_port)

	$Panel/ConnectContainer/ConnectButton.pressed.connect(_on_connect_button_pressed)

	$Panel/LoginContainer/LoginButton.pressed.connect(_on_login_button_pressed)
	$Panel/LoginContainer/CreateAccountButton.pressed.connect(_on_show_create_account_menu)

	$Panel/CreateAccountContainer/CreateAccountButton.pressed.connect(
		_on_create_account_button_pressed
	)

	$Panel/CreateAccountContainer/BackButton.pressed.connect(_on_back_create_account_button_pressed)


func show_connect_container():
	self.show()
	$Panel/ConnectContainer.show()
	$Panel/LoginContainer.hide()
	$Panel/CreateAccountContainer.hide()


func show_create_account_container():
	self.show()
	$Panel/ConnectContainer.hide()
	$Panel/LoginContainer.hide()
	$Panel/CreateAccountContainer.show()


func show_login_container():
	self.show()
	$Panel/ConnectContainer.hide()
	$Panel/LoginContainer.show()
	$Panel/CreateAccountContainer.hide()


func show_connect_error(message: String):
	$Panel/ConnectContainer/ErrorLabel.text = message


func show_login_error(message: String):
	$Panel/LoginContainer/ErrorLabel.text = message


func show_create_account_error(message: String):
	$Panel/CreateAccountContainer/ErrorLabel.text = message


func _on_connect_button_pressed():
	var server_address = $Panel/ConnectContainer/ServerAddressText.text
	var server_port = int($Panel/ConnectContainer/ServerPortText.text)

	if server_address == "" or server_port <= 0:
		$Panel/ConnectContainer/ErrorLabel.text = "Invalid server address or port"
		Gmf.logger.warn("Invalid server address or port")
		return

	connect_pressed.emit(server_address, server_port)


func _on_login_button_pressed():
	var username = $Panel/LoginContainer/UsernameText.text
	var password = $Panel/LoginContainer/PasswordText.text

	if username == "" or password == "":
		$Panel/LoginContainer/ErrorLabel.text = "Invalid username or password"
		Gmf.logger.warn("Invalid username or password")
		return

	login_pressed.emit(username, password)


func _on_show_create_account_menu():
	show_create_account_pressed.emit()


func _on_create_account_button_pressed():
	var username = $Panel/CreateAccountContainer/UsernameText.text
	var password = $Panel/CreateAccountContainer/PasswordText.text
	var repeat_password = $Panel/CreateAccountContainer/RepeatPasswordText.text

	if username == "" or password == "" or repeat_password == "":
		$Panel/CreateAccountContainer/ErrorLabel.text = "Fill in all fields"
		Gmf.logger.warn("Invalid username or password")
		return

	if password != repeat_password:
		$Panel/CreateAccountContainer/ErrorLabel.text = "Password mismatch"
		Gmf.logger.warn("Password mismatch")
		return

	create_account_pressed.emit(username, password)


func _on_back_create_account_button_pressed():
	back_create_account_pressed.emit()
