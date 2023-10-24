extends Control

var display_name: String = "":
	set(new_name):
		display_name = new_name
		$Name.text = new_name


func update_hp_bar(hp: int, hp_max: int):
	if hp_max > 0:
		$HPBar.value = float(hp * 100 / hp_max)
