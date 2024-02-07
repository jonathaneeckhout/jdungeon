extends Node

class_name StatsSynchronizerComponent

const COMPONENT_NAME: String = "stats_synchronizer"

enum TYPE {
	HP_MAX,
	HP,
	ENERGY_MAX,
	ENERGY,
	ENERGY_REGEN,
	ATTACK_POWER_MIN,
	ATTACK_POWER_MAX,
	ATTACK_SPEED,
	ATTACK_RANGE,
	DEFENSE,
	MOVEMENT_SPEED,
	LEVEL,
	EXPERIENCE,
	EXPERIENCE_NEEDED,
	HURT,
	HEAL,
	ENERGY_RECOVERY
}

const BASE_EXPERIENCE: int = 100

#Stats that are persistent
const StatListPermanent: Array[StringName] = [
	"hp_max",
	"energy_max",
	"energy_regen",
	"attack_power_min",
	"attack_power_max",
	"attack_speed",
	"attack_range",
	"defense",
	"movement_speed",
]
#Stats that serve as a meter of sorts and change often from external factors
const StatListCounter: Array[StringName] = [
	"hp",
	"energy",
	"level",
	"experience",
]
#Stats that have a base default value
const StatListWithDefaults: Array[StringName] = [
	"hp_max",
	"energy_max",
	"energy_regen",
	"attack_power_min",
	"attack_power_max",
	"defense",
	"movement_speed",
]

const StatListAll: Array[StringName] = StatListCounter + StatListPermanent

const ENERGY_INTERVAL_TIME: float = 1

signal loaded
signal stats_changed(stat_type: TYPE)
signal got_hurt(from: String, damage: int)
signal healed(from: String, healing: int)
signal energy_recovered(from: String, gained: int)
signal died
signal respawned
signal boosts_changed

@export var watcher_synchronizer: WatcherSynchronizerComponent

@export_group("Stats")
@export var hp_max: int = 100:
	set(val):
		hp_max = val
		stats_changed.emit(TYPE.HP_MAX)

@export var hp: int = hp_max:
	set(val):
		hp = val
		if hp <= 0:
			is_dead = true
			died.emit()
		else:
			if is_dead:
				respawned.emit()
			is_dead = false
		stats_changed.emit(TYPE.HP)

@export var energy_max: int = 100:
	set(val):
		energy_max = val
		stats_changed.emit(TYPE.ENERGY_MAX)

@export var energy: int = energy_max:
	set(val):
		energy = val
		stats_changed.emit(TYPE.ENERGY)

@export var energy_regen: int = 10:
	set(val):
		energy_regen = val
		stats_changed.emit(TYPE.ENERGY_REGEN)

@export var attack_power_min: int = 0:
	set(val):
		attack_power_min = val
		stats_changed.emit(TYPE.ATTACK_POWER_MIN)

@export var attack_power_max: int = 5:
	set(val):
		attack_power_max = val
		stats_changed.emit(TYPE.ATTACK_POWER_MAX)

@export var attack_speed: float = 0.8:
	set(val):
		attack_speed = val
		stats_changed.emit(TYPE.ATTACK_SPEED)

@export var attack_range: float = 64.0:
	set(val):
		attack_range = val
		stats_changed.emit(TYPE.ATTACK_RANGE)

@export var defense: int = 0:
	set(val):
		defense = val
		stats_changed.emit(TYPE.DEFENSE)

@export var movement_speed: float = 300.0:
	set(val):
		movement_speed = val
		stats_changed.emit(TYPE.MOVEMENT_SPEED)

@export var level: int = 1:
	set(val):
		level = clamp(val, 0, 100)
		experience_needed = calculate_experience_needed(level)
		stats_changed.emit(TYPE.LEVEL)

@export var experience: int = 0:
	set(val):
		experience = val
		stats_changed.emit(TYPE.EXPERIENCE)

@export var experience_needed: int = BASE_EXPERIENCE:
	set(val):
		experience_needed = val
		stats_changed.emit(TYPE.EXPERIENCE_NEEDED)

@export var experience_worth: int = 0

var active_boosts: Array[Boost]

var target_node: Node

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _stats_synchronizer_rpc: StatsSynchronizerRPC = null

var peer_id: int = 0
var is_dead: bool = false

var server_buffer: Array[Dictionary] = []
var ready_done: bool = false

@export_group("Stat Defaults")
@export var _default_hp_max: int = 100
@export var _default_energy_max: int = 100
@export var _default_energy_regen: int = 5
@export var _default_attack_power_min: int = 0
@export var _default_attack_power_max: int = 5
@export var _default_defense: int = 0
@export var _default_movement_speed: float = 300

var energy_regen_timer: Timer


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.get("component_list") != null:
		target_node.component_list[COMPONENT_NAME] = self

	# Get the ClockSynchronizer component.
	_clock_synchronizer = target_node.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the StatsSynchronizerRPC component.
	_stats_synchronizer_rpc = target_node.multiplayer_connection.component_list.get_component(
		StatsSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the StatsSynchronizerRPC component is present
	assert(_stats_synchronizer_rpc != null, "Failed to get StatsSynchronizerRPC component")

	if target_node.get("peer_id") != null:
		peer_id = target_node.peer_id

	# Physics only needed on client side
	if target_node.multiplayer_connection.is_server():
		set_physics_process(false)

		#Uses a setter to automatically call server_periodic_update() when true
		energy_regen_timer = Timer.new()
		energy_regen_timer.name = "EnergyRegenTimer"
		energy_regen_timer.wait_time = ENERGY_INTERVAL_TIME
		energy_regen_timer.autostart = true
		energy_regen_timer.timeout.connect(_on_energy_regen_timer_timeout)
		add_child(energy_regen_timer)

	else:
		#Wait until the connection is ready to synchronize stats
		if not target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		_stats_synchronizer_rpc.sync_stats(target_node.name)

	boosts_changed.connect(reload_boosts)

	# Make sure this line is called on server and client's side
	ready_done = true


func _physics_process(_delta: float):
	check_server_buffer()


func check_server_buffer():
	for i in range(server_buffer.size() - 1, -1, -1):
		var entry: Dictionary = server_buffer[i]
		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			assert(entry["type"] in TYPE.values(), "This is not a valid type")
			match entry["type"]:
				TYPE.HP_MAX:
					hp_max = entry["value"]
				TYPE.HP:
					hp = entry["value"]
				TYPE.ENERGY_MAX:
					energy_max = entry["value"]
				TYPE.ENERGY_REGEN:
					energy_regen = entry["value"]
				TYPE.ENERGY:
					energy = entry["value"]
				TYPE.ATTACK_POWER_MIN:
					attack_power_min = entry["value"]
				TYPE.ATTACK_POWER_MAX:
					attack_power_max = entry["value"]
				TYPE.ATTACK_SPEED:
					attack_speed = entry["value"]
				TYPE.ATTACK_RANGE:
					attack_range = entry["value"]
				TYPE.DEFENSE:
					defense = entry["value"]
				TYPE.MOVEMENT_SPEED:
					movement_speed = entry["value"]
				TYPE.LEVEL:
					level = entry["value"]
				TYPE.EXPERIENCE:
					experience = entry["value"]
				TYPE.EXPERIENCE_NEEDED:
					experience_needed = entry["value"]
				TYPE.HURT:
					hp = entry["hp"]
					got_hurt.emit(entry["from"], entry["damage"])
				TYPE.HEAL:
					hp = entry["hp"]
					healed.emit(entry["from"], entry["healing"])
				TYPE.ENERGY_RECOVERY:
					energy = entry["energy"]
					energy_recovered.emit(entry["from"], entry["recovered"])
			server_buffer.remove_at(i)


func hurt(from: Node, damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0
		if experience_worth > 0 and from.get("stats"):
			from.stats.add_experience(experience_worth)

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_hurt(
			peer_id, target_node.name, timestamp, from.name, hp, reduced_damage
		)

	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_hurt(
			watcher.peer_id, target_node.name, timestamp, from.name, hp, reduced_damage
		)

	got_hurt.emit(from.name, reduced_damage)

	return reduced_damage


func heal(from: String, healing: int) -> int:
	hp = min(hp_max, hp + healing)

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_heal(peer_id, target_node.name, timestamp, from, hp, healing)

	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_heal(
			watcher.peer_id, target_node.name, timestamp, from, hp, healing
		)

	healed.emit(from, healing)

	return healing


func reset_hp():
	hp = hp_max
	_sync_int_change(TYPE.HP, hp)


func reset_energy():
	energy = energy_max
	_sync_int_change(TYPE.ENERGY, energy)


func energy_recovery(from: String, recovered: int) -> int:
	energy = min(energy_max, energy + recovered)

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_energy_recovery(
			peer_id, target_node.name, timestamp, from, energy, recovered
		)

	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_energy_recovery(
			watcher.peer_id, target_node.name, timestamp, from, energy, recovered
		)

	energy_recovered.emit(from, recovered)

	return recovered


func kill():
	hp = 0
	_sync_int_change(TYPE.HP, hp)


func load_defaults():
	hp_max = _default_hp_max
	energy_max = _default_energy_max
	energy_regen = _default_energy_regen
	attack_power_min = _default_attack_power_min
	attack_power_max = _default_attack_power_max
	defense = _default_defense
	movement_speed = _default_movement_speed


func calculate_experience_needed(current_level: int):
	# TODO: Replace placeholder function to calculate experience needed to level up
	return BASE_EXPERIENCE + (BASE_EXPERIENCE * (pow(current_level, 2) - 1))


func add_level(amount: int):
	level += amount

	_sync_int_change(TYPE.LEVEL, level)


func add_experience(amount: int):
	experience += amount

	while experience >= experience_needed:
		experience -= experience_needed
		add_level(1)

	_sync_int_change(TYPE.EXPERIENCE, experience)


func get_attack_damage() -> float:
	return randi_range(attack_power_min, attack_power_max)


## Adds the [Boost] object to be applied on the stats and synchronizes the addition.
func apply_boost(boost: Boost):
	# Override any boost with an identical identifier, ignore if this boost doesn't have one.
	if boost.identifier != Boost.NO_IDENTIFIER:
		var existing_boost: Boost = get_boost_with_identifier(boost.identifier)
		if existing_boost is Boost:
			remove_boost(existing_boost)

	# Validate boost
	for stat_name in boost.stat_boost_dict.keys() + boost.stat_boost_modifier_dict.keys():
		if not stat_name in StatListAll:
			GodotLogger.error("The property '{0}' is not a stat.".format([stat_name]))

		if (
			typeof(boost.get_stat_boost(stat_name)) != TYPE_INT
			and typeof(boost.get_stat_boost(stat_name)) != TYPE_FLOAT
		):
			(
				GodotLogger
				. warn(
					(
						"The value type of the boost ({0}) must be type 1 or 2. This could cause unexpected behaviour."
						. format([typeof(boost.get_stat_boost(stat_name)), typeof(get(stat_name))])
					)
				)
			)

	# Add to list
	active_boosts.append(boost)

	var data: Dictionary = to_json(true)

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_response(peer_id, target_node.name, data)

	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_response(watcher.peer_id, target_node.name, data)

	# This signal calls reload_boosts()
	boosts_changed.emit()


## Attempts to remove a boost per reference.
func remove_boost(boost: Boost):
	if not active_boosts.has(boost):
		GodotLogger.warn("This boost does not belong to this component.")
		return

	active_boosts.erase(boost)

	var data: Dictionary = to_json(true)

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_response(peer_id, target_node.name, data)

	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_response(watcher.peer_id, target_node.name, data)

	boosts_changed.emit()


## Loads the default stats and re-applies every stored [Boost]
func reload_boosts():
	load_defaults()

	var flat_values: Dictionary = {}
	var modifier_values: Dictionary = {}

	# Start iterating trough stats to boost them
	for stat: String in StatListPermanent:
		# Prepare the flat and modifier values that the stat will be set-to and multiplied for.
		# The base value is the current (defaulted) value of the stat
		flat_values[stat] = get(stat)
		# The base for modifiers is 1, since it will be multiplied by other modifiers.
		modifier_values[stat] = 1

		for boost: Boost in active_boosts:
			# Store the bonuses of the boost added to the flat amount, as well as the modifiers
			flat_values[stat] += boost.get_stat_boost(stat)

			# Ignore modifiers of 1.
			if boost.get_stat_boost_modifier(stat) != 1:
				modifier_values[stat] *= boost.get_stat_boost_modifier(stat)

		# Set the stat to the flat value multiplied by the modifier
		set(stat, flat_values[stat] * modifier_values[stat])


## Attempts to get a reference to a [Boost] with the given identifier, if it exists.
func get_boost_with_identifier(identifier: String) -> Boost:
	for boost: Boost in active_boosts:
		if boost.identifier == identifier:
			return boost

	return null


func to_json(full: bool = false) -> Dictionary:
	var data: Dictionary = {}
	for stat_name in StatListCounter:
		data[stat_name] = get(stat_name)

	if data.size() != StatListCounter.size():
		GodotLogger.error("Discrepancy in the amount of stats, StatListCounter may be at fault.")

	if full:
		var dictForMerge: Dictionary = {}
		# Fill the dict with the permanent stats
		for stat_name in StatListPermanent:
			dictForMerge[stat_name] = get(stat_name)

		data.merge(dictForMerge)

		if data.size() != StatListCounter.size() + StatListPermanent.size():
			GodotLogger.error(
				"Discrepancy in the amount of stats, StatListPermanent may be at fault."
			)

	return data


func from_json(data: Dictionary, full: bool = false) -> bool:
	# Validation
	for stat_name in StatListCounter:
		if not stat_name in data:
			GodotLogger.warn('Failed to load stats from data, missing "%s" key' % stat_name)
			return false

	if full:
		for stat_name in StatListPermanent:
			if not stat_name in data:
				GodotLogger.warn('Failed to load stats from data, missing "%s" key' % stat_name)
				return false

	# Actually load the data
	for stat_name in StatListCounter:
		self.set(stat_name, data.get(stat_name))

	experience_needed = calculate_experience_needed(level)

	if full:
		for stat_name in StatListPermanent:
			self.set(stat_name, data.get(stat_name))

	loaded.emit()

	return true


#Client only (otherwise these synchs would be RPC'd to a client which does not support these synching methods)
func _sync_int_change(stat_type: TYPE, value: int):
	if not ready_done:
		return

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_int_change(
			peer_id, target_node.name, timestamp, stat_type, value
		)

	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_int_change(
			watcher.peer_id, target_node.name, timestamp, stat_type, value
		)


#Client only (otherwise these synchs would be RPC'd to a client which does not support these synching methods)
func _sync_float_change(stat_type: TYPE, value: float):
	if not ready_done:
		return

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_stats_synchronizer_rpc.sync_float_change(
			peer_id, target_node.name, timestamp, stat_type, value
		)
	for watcher in watcher_synchronizer.watchers:
		_stats_synchronizer_rpc.sync_float_change(
			watcher.peer_id, target_node.name, timestamp, stat_type, value
		)


func sync_stats(id: int):
	_stats_synchronizer_rpc.sync_response(id, target_node.name, to_json(true))


func sync_response(data: Dictionary):
	from_json(data, true)


#Called only by server
func sync_int_change(timestamp: float, stat_type: TYPE, value: int):
	server_buffer.append({"timestamp": timestamp, "type": stat_type, "value": value})


#Called only by server
func sync_float_change(timestamp: float, stat_type: TYPE, value: float):
	server_buffer.append({"timestamp": timestamp, "type": stat_type, "value": value})


#Called only by server
func sync_hurt(timestamp: float, from: String, current_hp: int, damage: int):
	server_buffer.append(
		{
			"type": TYPE.HURT,
			"timestamp": timestamp,
			"from": from,
			"hp": current_hp,
			"damage": damage
		}
	)


func sync_heal(timestamp: float, from: String, current_hp: int, healing: int):
	server_buffer.append(
		{
			"type": TYPE.HEAL,
			"timestamp": timestamp,
			"from": from,
			"hp": current_hp,
			"healing": healing
		}
	)


func sync_energy_recovery(timestamp: float, from: String, current_energy: int, recovered: int):
	server_buffer.append(
		{
			"type": TYPE.ENERGY_RECOVERY,
			"timestamp": timestamp,
			"from": from,
			"energy": current_energy,
			"recovered": recovered
		}
	)


func _on_energy_regen_timer_timeout():
	if not ready_done:
		return

	if energy != energy_max:
		energy_recovery(target_node.get_name(), energy_regen)
