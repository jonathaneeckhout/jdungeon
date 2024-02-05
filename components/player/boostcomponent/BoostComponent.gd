extends Node

class_name BoostComponent

@export var stats_synchronizer: StatsSynchronizerComponent = null
@export var equipment_synchronizer: EquipmentSynchronizerComponent = null

@export var hp_gain_per_level: int = 8
@export var attack_power_gain_per_level: float = 0.2

var _target_node: Node


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if not _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	stats_synchronizer.stats_changed.connect(_on_stats_changed)

	equipment_synchronizer.loaded.connect(_on_equipment_loaded)
	equipment_synchronizer.item_added.connect(_on_item_equiped)
	equipment_synchronizer.item_removed.connect(_on_item_unequiped)


func _calculate_level_boost() -> Boost:
	var boost: Boost = Boost.new()
	boost.hp_max = int((stats_synchronizer.level - 1) * hp_gain_per_level)
	boost.attack_power_min = int(stats_synchronizer.level * attack_power_gain_per_level)
	boost.attack_power_max = boost.attack_power_min
	return boost


func _calculate_and_apply_boosts():
	var boost: Boost = _calculate_level_boost()
	boost.identifier = "player_level"
	var equipment_boost: Boost = equipment_synchronizer.get_boost()
	equipment_boost.identifier = "player_equipment"

	stats_synchronizer.apply_boost(equipment_boost)
	stats_synchronizer.apply_boost(boost)


func _update_boosts():
	stats_synchronizer.load_defaults()

	_calculate_and_apply_boosts()


func _on_stats_changed(stat_type: StatsSynchronizerComponent.TYPE):
	if stat_type == StatsSynchronizerComponent.TYPE.LEVEL:
		_update_boosts()


func _on_equipment_loaded():
	_update_boosts()


func _on_item_equiped(_item_uuid: String, _item_class: String):
	_update_boosts()


func _on_item_unequiped(_item_uuid: String):
	_update_boosts()
