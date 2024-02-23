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
		health_synchronizer.loaded.connect(_on_health_loaded)
		health_synchronizer.got_hurt.connect(_on_got_hurt)
		health_synchronizer.healed.connect(_on_healed)

	if energy_synchronizer:
		energy_synchronizer.loaded.connect(_on_energy_loaded)
		energy_synchronizer.energy_consumed.connect(_on_energy_consumed)
		energy_synchronizer.energy_recovered.connect(_on_energy_recovered)


func _update_hp_bar():
	if health_synchronizer.hp_max > 0:
		$HPBar.value = float(health_synchronizer.hp * $HPBar.max_value / health_synchronizer.hp_max)


func _update_energy_bar():
	if energy_synchronizer.energy_max > 0:
		$EnergyBar.value = float(
			energy_synchronizer.energy * $EnergyBar.max_value / energy_synchronizer.energy_max
		)


func _on_health_loaded():
	_update_hp_bar()


func _on_got_hurt(_from: String, _damage: int):
	_update_hp_bar()


func _on_healed(_from: String, _healing: int):
	_update_hp_bar()


func _on_energy_loaded():
	_update_energy_bar()


func _on_energy_consumed(_from: String, _amount: int):
	_update_energy_bar()


func _on_energy_recovered(_from: String, _amount: int):
	_update_energy_bar()
