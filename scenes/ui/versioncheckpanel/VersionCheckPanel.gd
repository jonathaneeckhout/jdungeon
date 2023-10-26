extends Control

signal request_response(response: bool)

var version: String = ""

@onready var http_request = HTTPRequest.new()
@onready var exit_button: Button = $Panel/ConnectContainer/CloseMarginContainer/CloseButton
@onready var check_label: Label = $Panel/ConnectContainer/VBoxContainer/CheckLabel


func _ready():
	exit_button.pressed.connect(_on_exit_button_pressed)

	if J.global.env_debug:
		J.logger.info("Not checking versions in debug configuration")
		return

	if not FileAccess.file_exists(J.global.env_version_file):
		J.logger.error("Version file=[%s] does not exist" % J.global.env_version_file)
		return

	var file = FileAccess.open(J.global.env_version_file, FileAccess.READ)
	if file == null:
		J.logger.warn("Could not open file=[%s] to read" % J.global.env_version_file)
		return null

	var string_data: String = file.get_as_text()

	var json_data: Dictionary = JSON.parse_string(string_data)

	version = json_data.get("version", "")

	if version != "":
		J.logger.info("Current Version is %s" % version)
	else:
		J.logger.error("Version file does not contain version information")

	var client_tls_options: TLSOptions = TLSOptions.client()

	http_request.set_tls_options(client_tls_options)
	http_request.request_completed.connect(_http_request_completed)
	add_child(http_request)


func check_version() -> bool:
	if version == "":
		J.logger.warn("No version detected on client side")
		return false

	var request_url = "https://%s/version" % [J.global.env_server_address]
	var headers = ["Content-Type: application/json"]

	var error = http_request.request(request_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		J.logger.error("An error occurred in the HTTP request.")
		return false

	J.logger.info("Sending out get request to %s" % [request_url])

	var response = await request_response
	if response:
		check_label.text = "Client's version matches the Server's version. \n Starting the game."
	else:
		check_label.text = "Client's version does not matches the Server's version. \n Please exit the game."
		exit_button.show()

	return response


func _on_exit_button_pressed():
	get_tree().quit()


func _http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		J.logger.warn("HTTPRequest failed")
		request_response.emit(false)
		return

	if response_code != 200:
		J.logger.warn("Http response error=[%d]" % response_code)
		request_response.emit(false)
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if !"error" in response or response["error"] or !"version" in response:
		J.logger.warn("Error or invalid response format")
		request_response.emit(false)
		return

	var matches: bool = response["version"] == version

	J.logger.info(
		(
			"Current client's version %s the server's version" % "matches"
			if matches
			else "does not matches"
		)
	)

	request_response.emit(matches)
