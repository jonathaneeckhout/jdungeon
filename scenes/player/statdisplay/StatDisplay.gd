extends Control
## Set the [member stats] variable to start updating

class_name StatsDisplay

@export var health: HealthSynchronizerComponent = null
@export var energy: EnergySynchronizerComponent = null
@export var combat: CombatAttributeSynchronizerComponent = null

@export var accept_input: bool = true

@onready var hp_value_label: Label = $ScrollContainer/StatList/HPSplitContainer/Value
@onready var hp_max_value_label: Label = $ScrollContainer/StatList/HPMaxSplitContainer/Value
@onready var energy_value_label: Label = $ScrollContainer/StatList/EnergySplitContainer/Value
@onready var energy_max_value_label: Label = $ScrollContainer/StatList/EnergyMaxSplitContainer/Value
@onready
var energy_regeneration_value_label: Label = $ScrollContainer/StatList/EnergyRegenSplitContainer/Value
@onready var level_value_label: Label = $ScrollContainer/StatList/LevelSplitContainer/Value
@onready var experience_value_label: Label = $ScrollContainer/StatList/ExperienceSplitContainer/Value
@onready
var experience_needed_value_label: Label = $ScrollContainer/StatList/ExperienceNeededSplitContainer/Value
@onready
var attack_power_min_value_label: Label = $ScrollContainer/StatList/AttackPowerMinSplitContainer/Value
@onready
var attack_power_max_value_label: Label = $ScrollContainer/StatList/AttackPowerMaxSplitContainer/Value
@onready var defense_value_label: Label = $ScrollContainer/StatList/DefenseSplitContainer/Value


func _ready():
	health.loaded.connect(_on_health_loaded)
	health.got_hurt.connect(_on_got_hurt)
	health.healed.connect(_on_healed)

	energy.loaded.connect(_on_energy_loaded)
	energy.energy_consumed.connect(_on_energy_consumed)
	energy.energy_recovered.connect(_on_energy_recovered)


func _unhandled_input(event: InputEvent) -> void:
	if accept_input and event.is_action_pressed("j_toggle_stats"):
		visible = !visible


func _renew_values():
	hp_value_label.text = str(health.hp)
	hp_max_value_label.text = str(health.hp_max)
	energy_value_label.text = str(energy.energy)
	energy_max_value_label.text = str(energy.energy_max)
	energy_regeneration_value_label.text = str(energy.energy_regen)
	# level_value_label.text = str(stats.level)
	# experience_value_label.text = str(stats.experience)
	# experience_needed_value_label.text = str(stats.experience_needed)
	attack_power_min_value_label.text = str(combat.attack_power_min)
	attack_power_max_value_label.text = str(combat.attack_power_max)
	defense_value_label.text = str(combat.defense)


func _on_health_loaded():
	_renew_values()


func _on_got_hurt(_from: String, _damage: int):
	_renew_values()


func _on_healed(_from: String, _healing: int):
	_renew_values()


func _on_energy_loaded():
	_renew_values()


func _on_energy_consumed(_from: String, _amount: int):
	_renew_values()


func _on_energy_recovered(_from: String, _amount: int):
	_renew_values()