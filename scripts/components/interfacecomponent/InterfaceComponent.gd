extends Control

class_name InterfaceComponent

@export var stats_synchronizer: StatsSynchronizerComponent


func _ready():
	stats_synchronizer.stats_changed.connect(_on_stats_changed)


var display_name: String = "":
	set(new_name):
		display_name = new_name
		$Name.text = new_name


func update_hp_bar(hp: int, hp_max: int):
	if hp_max > 0:
		$HPBar.value = float(hp * 100 / hp_max)


func _on_stats_changed(stat_type: StatsSynchronizerComponent.TYPE):
	if (
		stat_type == StatsSynchronizerComponent.TYPE.HP_MAX
		or stat_type == StatsSynchronizerComponent.TYPE.HP
	):
		if stats_synchronizer.hp_max > 0:
			$HPBar.value = float(stats_synchronizer.hp * 100 / stats_synchronizer.hp_max)
