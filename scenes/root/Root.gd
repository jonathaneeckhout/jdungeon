extends Node


func _ready():
	$SelectRunMode/VBoxContainer/RunAsServerButton.pressed.connect(_on_run_as_server_pressed)
	$SelectRunMode/VBoxContainer/RunAsClientButton.pressed.connect(_on_run_as_client_pressed)

	$SelectRunMode/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)

	$SelectRunMode/ComfirmResetContainer/ResetYesButton.pressed.connect(_on_reset_yes_pressed)
	$SelectRunMode/ComfirmResetContainer/ResetNoButton.pressed.connect(_on_reset_no_pressed)

	J.register_player_scene("res://scenes/player/Player.tscn")

	register_items()


func register_items():
	J.register_item_scene("Gold", "res://scenes/items/varia/gold/Gold.tscn")

	J.register_item_scene(
		"HealthPotion", "res://scenes/items/consumables/healthpotion/HealthPotion.tscn"
	)

	J.register_item_scene("Axe", "res://scenes/items/equipment/weapons/axe/Axe.tscn")
	J.register_item_scene("Sword", "res://scenes/items/equipment/weapons/sword/Sword.tscn")
	J.register_item_scene("Club", "res://scenes/items/equipment/weapons/club/Club.tscn")

	J.register_item_scene(
		"LeatherHelm", "res://scenes/items/equipment/armour/leatherhelm/LeatherHelm.tscn"
	)
	J.register_item_scene(
		"LeatherBody", "res://scenes/items/equipment/armour/leatherbody/LeatherBody.tscn"
	)
	J.register_item_scene(
		"LeatherArms", "res://scenes/items/equipment/armour/leatherarms/LeatherArms.tscn"
	)
	J.register_item_scene(
		"LeatherLegs", "res://scenes/items/equipment/armour/leatherlegs/LeatherLegs.tscn"
	)

	J.register_item_scene(
		"ChainMailHelm", "res://scenes/items/equipment/armour/chainmailhelm/ChainMailHelm.tscn"
	)
	J.register_item_scene(
		"ChainMailBody", "res://scenes/items/equipment/armour/chainmailbody/ChainMailBody.tscn"
	)
	J.register_item_scene(
		"ChainMailArms", "res://scenes/items/equipment/armour/chainmailarms/ChainMailArms.tscn"
	)
	J.register_item_scene(
		"ChainMailLegs", "res://scenes/items/equipment/armour/chainmaillegs/ChainMailLegs.tscn"
	)

	J.register_item_scene(
		"PlateHelm", "res://scenes/items/equipment/armour/platehelm/PlateHelm.tscn"
	)
	J.register_item_scene(
		"PlateBody", "res://scenes/items/equipment/armour/platebody/PlateBody.tscn"
	)
	J.register_item_scene(
		"PlateArms", "res://scenes/items/equipment/armour/platearms/PlateArms.tscn"
	)
	J.register_item_scene(
		"PlateLegs", "res://scenes/items/equipment/armour/platelegs/PlateLegs.tscn"
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


func _on_reset_pressed():
	$SelectRunMode/VBoxContainer.hide()
	$SelectRunMode/ComfirmResetContainer.show()


func _on_reset_yes_pressed():
	# Remove the database file if it exists to be in a clean state after this button was pressed
	if FileAccess.file_exists(JSONDatabaseBackend.USERS_FILEPATH):
		DirAccess.remove_absolute(JSONDatabaseBackend.USERS_FILEPATH)

	$SelectRunMode/VBoxContainer.show()
	$SelectRunMode/ComfirmResetContainer.hide()


func _on_reset_no_pressed():
	$SelectRunMode/VBoxContainer.show()
	$SelectRunMode/ComfirmResetContainer.hide()
