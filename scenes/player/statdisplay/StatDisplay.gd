extends Control

@export var player: JPlayerBody2D

@onready var hp_value_label: Label = $ScrollContainer/StatList/HPSplitContainer/Value
@onready var hp_max_value_label: Label = $ScrollContainer/StatList/HPMaxSplitContainer/Value
@onready var level_value_label: Label = $ScrollContainer/StatList/LevelSplitContainer/Value
@onready var experience_value_label: Label = $ScrollContainer/StatList/ExperienceSplitContainer/Value
@onready
var experience_needed_value_label: Label = $ScrollContainer/StatList/ExperienceNeededSplitContainer/Value
@onready
var attack_power_min_value_label: Label = $ScrollContainer/StatList/AttackPowerMinSplitContainer/Value
@onready
var attack_power_max_value_label: Label = $ScrollContainer/StatList/AttackPowerMaxSplitContainer/Value
@onready var defense_value_label: Label = $ScrollContainer/StatList/DefenseSplitContainer/Value


func _ready() -> void:
	if player:
		player.stats.stats_changed.connect(_on_stats_changed)
		renew_values()
	else:
		J.logger.error("Player is not assigned")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("j_toggle_stats"):
		visible = !visible


func renew_values():
	hp_value_label.text = str(player.stats.hp)
	hp_max_value_label.text = str(player.stats.hp_max)
	level_value_label.text = str(player.stats.level)
	experience_value_label.text = str(player.stats.experience)
	experience_needed_value_label.text = str(player.stats.experience_needed)
	attack_power_min_value_label.text = str(player.stats.attack_power_min)
	attack_power_max_value_label.text = str(player.stats.attack_power_max)
	defense_value_label.text = str(player.stats.defense)


func _on_stats_changed(type: JStats.TYPE):
	match type:
		JStats.TYPE.HP_MAX:
			hp_max_value_label.text = str(player.stats.hp_max)
		JStats.TYPE.HP:
			hp_value_label.text = str(player.stats.hp)
		JStats.TYPE.ATTACK_POWER_MIN:
			attack_power_min_value_label.text = str(player.stats.attack_power_min)
		JStats.TYPE.ATTACK_POWER_MAX:
			attack_power_max_value_label.text = str(player.stats.attack_power_max)
		JStats.TYPE.ATTACK_SPEED:
			# TODO: not added yet
			pass
		JStats.TYPE.ATTACK_RANGE:
			# TODO: not added yet
			pass
		JStats.TYPE.DEFENSE:
			defense_value_label.text = str(player.stats.defense)
		JStats.TYPE.MOVEMENT_SPEED:
			# TODO: not added yet
			pass
		JStats.TYPE.LEVEL:
			level_value_label.text = str(player.stats.level)
		JStats.TYPE.EXPERIENCE:
			experience_value_label.text = str(player.stats.experience)
		JStats.TYPE.EXPERIENCE_NEEDED:
			experience_needed_value_label.text = str(player.stats.experience_needed)
