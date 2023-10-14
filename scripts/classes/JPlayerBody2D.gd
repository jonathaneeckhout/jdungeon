extends JBody2D

class_name JPlayerBody2D

signal respawned

var peer_id: int = 1
var username: String = ""

var player_synchronizer: JPlayerSynchronizer
var player_input: JPlayerInput
var player_behavior: JPlayerBehavior
var inventory: JInventory
var equipment: JEquipment

var persistency_timer: Timer
var respawn_timer: Timer


func _init():
	super()

	entity_type = J.ENTITY_TYPE.PLAYER

	collision_layer += J.PHYSICS_LAYER_PLAYERS

	player_synchronizer = JPlayerSynchronizer.new()
	player_synchronizer.name = "PlayerSynchronizer"
	player_synchronizer.player = self
	player_synchronizer.synchronizer = synchronizer
	add_child(player_synchronizer)

	inventory = JInventory.new()
	inventory.name = "Inventory"
	inventory.player = self
	add_child(inventory)

	equipment = JEquipment.new()
	equipment.name = "Equipment"
	equipment.player = self
	add_child(equipment)

	if J.is_server():
		player_behavior = JPlayerBehavior.new()
		player_behavior.name = "PlayerBehavior"
		player_behavior.player = self
		player_behavior.player_synchronizer = player_synchronizer
		player_behavior.player_stats = stats
		add_child(player_behavior)

		persistency_timer = Timer.new()
		persistency_timer.name = "PersistencyTimer"
		persistency_timer.autostart = true
		persistency_timer.wait_time = J.PERSISTENCY_INTERVAL
		persistency_timer.timeout.connect(_on_persistency_timer_timeout)
		add_child(persistency_timer)

		respawn_timer = Timer.new()
		respawn_timer.name = "RespawnTimer"
		respawn_timer.autostart = false
		respawn_timer.wait_time = J.PLAYER_RESPAWN_TIME
		respawn_timer.timeout.connect(_on_respawn_timer_timeout)
		add_child(respawn_timer)

	else:
		player_input = JPlayerInput.new()
		player_input.name = "PlayerInput"
		add_child(player_input)

		player_input.move.connect(_on_move)
		player_input.interact.connect(_on_interact)


func die():
	super()

	respawn_timer.start(J.PLAYER_RESPAWN_TIME)


func store_data():
	J.logger.info("Storing player=[%s]'s persistent data" % username)
	JPlayerPersistency.store_data(self)


func _on_move(target_position: Vector2):
	player_synchronizer.move.rpc_id(1, target_position)


func _on_interact(target_name: String):
	player_synchronizer.interact.rpc_id(1, target_name)


func _on_persistency_timer_timeout():
	store_data()


func _on_respawn_timer_timeout():
	var respawn_location: Vector2 = J.world.find_player_respawn_location(self.position)

	# Set the player to the respawn location
	position = respawn_location

	#Let's bring the player back to life
	stats.reset_hp()

	velocity = Vector2.ZERO
	loop_animation = "Idle"
	synchronizer.sync_loop_animation(loop_animation, velocity)

	# Let the player take part of the world again
	collision_layer += J.PHYSICS_LAYER_WORLD

	respawned.emit()

	synchronizer.sync_respawn()
