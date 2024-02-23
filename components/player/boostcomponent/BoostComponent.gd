extends Node

class_name BoostComponent

@export_group("Input Components")
@export var class_component: ClassComponent = null
@export var equipment_synchronizer: EquipmentSynchronizerComponent = null

@export_group("Output Components")
@export var health_synchronizer: HealthSynchronizerComponent = null
@export var energy_synchronizer: EnergySynchronizerComponent = null
@export var combat_attribute_synchronizer: CombatAttributeSynchronizerComponent = null

var _target_node: Node


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if not _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	equipment_synchronizer.changed.connect(_on_equipment_changed)


func _calculate_and_apply_boosts():
	var boost: Boost = class_component.get_boost()

	boost.add_boost(equipment_synchronizer.get_boost())

	health_synchronizer.apply_boost(boost)
	energy_synchronizer.apply_boost(boost)
	combat_attribute_synchronizer.apply_boost(boost)


func _on_equipment_changed():
	_calculate_and_apply_boosts()
