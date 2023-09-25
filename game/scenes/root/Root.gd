extends Node


func _ready():
	$SelectRunMode/VBoxContainer/RunAsServerButton.pressed.connect(_on_run_as_server_pressed)
	$SelectRunMode/VBoxContainer/RunAsClientButton.pressed.connect(_on_run_as_client_pressed)

	GMF.register_player_scene("res://game/scenes/player/Player.tscn")


func _on_run_as_server_pressed():
	GMF.logger.info("Running as server")
	$SelectRunMode.queue_free()

	if not GMF.init_server():
		GMF.logger.error("Could not initialize the server, quitting")
		get_tree().quit()
		return

	var world = load("res://game/scenes/world/World.tscn").instantiate()
	world.name = "World"
	self.add_child(world)

	if not GMF.server.start():
		GMF.logger.error("Failed to start server, quitting")
		get_tree().quit()
		return


func _on_run_as_client_pressed():
	GMF.logger.info("Running as client")
	$SelectRunMode.queue_free()

	if not GMF.init_client():
		GMF.logger.err("Could not initialize the client, quitting")
		get_tree().quit()
		return

	var world = load("res://game/scenes/world/World.tscn").instantiate()
	world.name = "World"
	self.add_child(world)
