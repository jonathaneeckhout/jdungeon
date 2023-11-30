extends Control

class_name InterfaceComponent

@export var stats_synchronizer: StatsSynchronizerComponent


func _ready():
	stats_synchronizer.stats_changed.connect(_on_stats_changed)


var show_energy: bool = false:
	set(val):
		show_energy = val
		$EnergyBar.visible = show_energy

var display_name: String = "":
	set(new_name):
		display_name = new_name
		$Name.text = new_name


## Deprecated function
func update_hp_bar(hp: int, hp_max: int):
	if hp_max > 0:
		$HPBar.value = float(hp * $HPBar.max_value / hp_max)


func _on_stats_changed(stat_type: StatsSynchronizerComponent.TYPE):
	if (
		stat_type == StatsSynchronizerComponent.TYPE.HP_MAX
		or stat_type == StatsSynchronizerComponent.TYPE.HP
	):
		if stats_synchronizer.hp_max > 0:
			$HPBar.value = float(
				stats_synchronizer.hp * $HPBar.max_value / stats_synchronizer.hp_max
			)

	elif (
		stat_type == StatsSynchronizerComponent.TYPE.ENERGY_MAX
		or stat_type == StatsSynchronizerComponent.TYPE.ENERGY
	):
		if stats_synchronizer.energy_max > 0:
			$EnergyBar.value = float(
				stats_synchronizer.energy * $HPBar.max_value / stats_synchronizer.energy_max
			)
