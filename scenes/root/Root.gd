extends Node


func _ready():
	$SelectRunMode/VBoxContainer/RunAsServerButton.pressed.connect(_on_run_as_server_pressed)
	$SelectRunMode/VBoxContainer/RunAsClientButton.pressed.connect(_on_run_as_client_pressed)

	J.register_player_scene("res://scenes/player/Player.tscn")


func _on_run_as_server_pressed():
	J.logger.info("Running as server")
	$SelectRunMode.queue_free()

	if not J.init_server():
		J.logger.error("Could not initialize the server, quitting")
		get_tree().quit()
		return

	var world = load("res://scenes/world/World.tscn").instantiate()
	world.name = "World"
	self.add_child(world)

	if not J.server.start():
		J.logger.error("Failed to start server, quitting")
		get_tree().quit()
		return


func _on_run_as_client_pressed():
	J.logger.info("Running as client")
	$SelectRunMode.queue_free()

	if not J.init_client():
		J.logger.err("Could not initialize the client, quitting")
		get_tree().quit()
		return

	var world = load("res://scenes/world/World.tscn").instantiate()
	world.name = "World"
	self.add_child(world)
