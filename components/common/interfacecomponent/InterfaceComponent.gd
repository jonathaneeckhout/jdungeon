extends Control

class_name InterfaceComponent

@export var health_synchronizer: HealthSynchronizerComponent
@export var energy_synchronizer: EnergySynchronizerComponent

var show_energy: bool = false:
	set(val):
		show_energy = val
		$EnergyBar.visible = show_energy

var display_name: String = "":
	set(new_name):
		display_name = new_name
		$Name.text = new_name


func _ready():
	if health_synchronizer:
		health_synchronizer.changed.connect(_on_health_changed)

	if energy_synchronizer:
		energy_synchronizer.changed.connect(_on_energy_changed)


func _update_hp_bar():
	if health_synchronizer.hp_max > 0:
		$HPBar.value = float(health_synchronizer.hp * $HPBar.max_value / health_synchronizer.hp_max)


func _update_energy_bar():
	if energy_synchronizer.energy_max > 0:
		$EnergyBar.value = float(
			energy_synchronizer.energy * $EnergyBar.max_value / energy_synchronizer.energy_max
		)


func _on_health_changed():
	_update_hp_bar()


func _on_energy_changed():
	_update_energy_bar()
