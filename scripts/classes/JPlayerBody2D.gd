extends JBody2D

class_name JPlayerBody2D

const PLAYER_HP_MAX_DEFAULT: int = 100
const PLAYER_ATTACK_POWER_MIN_DEFAULT: int = 1
const PLAYER_ATTACK_POWER_MAX_DEFAULT: int = 5
const PLAYER_ATTACK_SPEED_DEFAULT: float = 0.8
const PLAYER_ATTACK_RANGE_DEFAULT: float = 64.0
const PLAYER_DEFENSE_DEFAULT: int = 0
const PLAYER_MOVEMENT_SPEED_DEFAULT: float = 300.0

const PLAYER_HP_GAIN_PER_LEVEL: int = 8
const PLAYER_ATTACK_POWER_GAIN_PER_LEVEL: float = 0.2

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
		respawn_timer.one_shot = true
		respawn_timer.wait_time = J.PLAYER_RESPAWN_TIME
		respawn_timer.timeout.connect(_on_respawn_timer_timeout)
		add_child(respawn_timer)

	else:
		player_input = JPlayerInput.new()
		player_input.name = "PlayerInput"
		add_child(player_input)

		player_input.move.connect(_on_move)
		player_input.interact.connect(_on_interact)


func _ready():
	super()

	stats.gained_level.connect(__on_gained_level)
	equipment.loaded.connect(__on_equipment_loaded)
	equipment.item_added.connect(__on_equipment_added)
	equipment.item_removed.connect(__on_equipment_removed)

	if not J.is_server() and J.client.player:
		equipment.sync_equipment.rpc_id(1, J.client.player.peer_id)

	# Should've been called by equipment loaded, but calling again to be sure
	calculate_and_apply_boosts()


# Called by JWorld when a player is added
func load_data():
	J.logger.info("Loading player=[%s]'s default stats" % username)
	load_default_stats()

	J.logger.info("Loading player=[%s]'s persistent data" % username)
	load_persistent_data()

	J.logger.info("Calculating and applying player=[%s]'s boosts" % username)
	calculate_and_apply_boosts()

	J.logger.info("Loading player=[%s]'s data done" % username)


func load_default_stats():
	stats.hp_max = PLAYER_HP_MAX_DEFAULT
	stats.attack_power_min = PLAYER_ATTACK_POWER_MIN_DEFAULT
	stats.attack_power_max = PLAYER_ATTACK_POWER_MAX_DEFAULT
	stats.defense = PLAYER_DEFENSE_DEFAULT


func load_persistent_data() -> bool:
	var data: Dictionary = J.server.database.load_player_data(username)

	if data.is_empty():
		J.logger.info("Player=[%s] does not have peristent data" % username)
		return true

	# This function's minimal requirement is that the postion key is available in the data
	if not "position" in data:
		J.logger.warn('Invalid format of data, missing "position" key')
		return false

	if not "x" in data["position"]:
		J.logger.warn('Invalid format of data, missing "x" key')
		return false

	if not "y" in data["position"]:
		J.logger.warn('Invalid format of data, missing "y" key')
		return false

	position = Vector2(data["position"]["x"], data["position"]["y"])

	if "stats" in data:
		if not stats.from_json(data["stats"]):
			J.logger.warn("Failed to load stats from data")

	if "inventory" in data:
		if not inventory.from_json(data["inventory"]):
			J.logger.warn("Failed to load inventory from data")

	if "equipment" in data:
		if not equipment.from_json(data["equipment"]):
			J.logger.warn("Failed to load equipment from data")

	return true


func store_persistent_data() -> bool:
	var data: Dictionary = {
		"position": {"x": position.x, "y": position.y},
		"stats": stats.to_json(),
		"inventory": inventory.to_json(),
		"equipment": equipment.to_json()
	}

	return J.server.database.store_player_data(username, data)


func die():
	super()

	collision_layer -= J.PHYSICS_LAYER_PLAYERS

	respawn_timer.start(J.PLAYER_RESPAWN_TIME)


func respawn(location: Vector2):
	super(location)

	collision_layer += J.PHYSICS_LAYER_PLAYERS


func calculate_and_apply_boosts():
	var boost: JBoost = calculate_level_boost()

	var equipment_boost: JBoost = equipment.get_boost()
	boost.add_boost(equipment_boost)

	stats.apply_boost(boost)


func update_boosts():
	load_default_stats()

	calculate_and_apply_boosts()


func calculate_level_boost() -> JBoost:
	var boost: JBoost = JBoost.new()
	boost.hp_max = int((stats.level - 1) * PLAYER_HP_GAIN_PER_LEVEL)
	boost.attack_power_min = int(stats.level * PLAYER_ATTACK_POWER_GAIN_PER_LEVEL)
	boost.attack_power_max = boost.attack_power_min
	return boost


func _on_move(target_position: Vector2):
	player_synchronizer.move.rpc_id(1, target_position)


func _on_interact(target_name: String):
	player_synchronizer.interact.rpc_id(1, target_name)


func _on_persistency_timer_timeout():
	store_persistent_data()


func _on_respawn_timer_timeout():
	var respawn_location: Vector2 = J.world.find_player_respawn_location(self.position)
	respawn(respawn_location)


func __on_gained_level():
	update_boosts()


func __on_equipment_loaded():
	update_boosts()


func __on_equipment_added(_item_uuid: String, _item_class: String):
	update_boosts()


func __on_equipment_removed(_item_uuid: String):
	update_boosts()
