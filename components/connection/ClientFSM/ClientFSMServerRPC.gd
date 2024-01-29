extends Node

class_name ClientFSMServerRPC

const COMPONENT_NAME = "ClientFSMServerRPC"

const COOKIE_TIMER_INTERVAL: float = 10.0
const COOKIE_VALID_TIME: float = 60.0

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null

var users: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done

	if _multiplayer_connection.is_server():
		var check_cookie_timer: Timer = Timer.new()
		check_cookie_timer.name = "CheckCookieTimer"
		check_cookie_timer.autostart = true
		check_cookie_timer.one_shot = false
		check_cookie_timer.wait_time = COOKIE_TIMER_INTERVAL
		check_cookie_timer.timeout.connect(_on_check_cookie_timer_timeout)
		add_child(check_cookie_timer)


func register_user(username: String, cookie: String):
	GodotLogger.info("Registering user=[%s]" % username)

	var user = MultiplayerConnection.User.new()
	user.username = username
	user.cookie = cookie
	users[username] = user


func _on_check_cookie_timer_timeout():
	var to_be_deleted: Array[String] = []
	var current_time: float = Time.get_unix_time_from_system()

	for username in users:
		var user: MultiplayerConnection.User = users[username]
		if (current_time - user.registered_time) > COOKIE_VALID_TIME:
			to_be_deleted.append(username)

	for username in to_be_deleted:
		GodotLogger.info("User=[%s] cookie expired, removing from list" % username)
		users.erase(username)
