extends Node


func _ready():
	$SelectRunMode/VBoxContainer/RunAsServerButton.pressed.connect(_on_run_as_server_pressed)
	$SelectRunMode/VBoxContainer/RunAsClientButton.pressed.connect(_on_run_as_client_pressed)

	J.register_player_scene("res://scenes/player/Player.tscn")

	register_enemies()
	register_npcs()
	register_items()
	
	parse_cmd_arguments()


func register_enemies():
	J.register_enemy_scene("Sheep", "res://scenes/enemies/Sheep/Sheep.tscn")
	J.register_enemy_scene("TreeTrunkGuy", "res://scenes/enemies/TreeTrunkGuy/TreeTrunkGuy.tscn")


func register_npcs():
	J.register_npc_scene("MilkLady", "res://scenes/npcs/milklady/Milklady.tscn")


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

func parse_cmd_arguments():
	var args:PackedStringArray = OS.get_cmdline_args()
	if not args.is_empty():
		J.logger.info("Founds launch arguments. ", str(args))
		
	for arg in args:
		if arg == "j_client":
			$SelectRunMode/VBoxContainer/RunAsClientButton.pressed.emit()
			break
			
		elif "j_server" in args:
			$SelectRunMode/VBoxContainer/RunAsServerButton.pressed.emit()
			break


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
		J.logger.error("Could not initialize the client, quitting")
		get_tree().quit()
		return

	var world = load("res://scenes/world/World.tscn").instantiate()
	world.name = "World"
	self.add_child(world)
