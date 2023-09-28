extends Node


func _ready():
	$SelectRunMode/VBoxContainer/RunAsServerButton.pressed.connect(_on_run_as_server_pressed)
	$SelectRunMode/VBoxContainer/RunAsClientButton.pressed.connect(_on_run_as_client_pressed)

	J.register_player_scene("res://scenes/player/Player.tscn")

	register_items()


func register_items():
	J.register_item_scene("Gold", "res://scenes/items/varia/gold/Gold.tscn")
	J.register_item_scene(
		"HealthPotion", "res://scenes/items/consumables/healthpotion/HealthPotion.tscn"
	)
	J.register_item_scene("Axe", "res://scenes/items/equipment/weapons/axe/Axe.tscn")
	J.register_item_scene("Club", "res://scenes/items/equipment/weapons/club/Club.tscn")
	J.register_item_scene(
		"ChainMailBody", "res://scenes/items/equipment/armour/chainmailbody/ChainMailBody.tscn"
	)
	J.register_item_scene(
		"PlateBody", "res://scenes/items/equipment/armour/platebody/PlateBody.tscn"
	)


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
