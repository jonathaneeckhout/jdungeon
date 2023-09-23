extends Control

var display_name: String = "":
	set(new_name):
		display_name = new_name
		$Name.text = new_name


func update_hp_bar(hp: int, max_hp: int):
	$HPBar.value = float(hp * 100 / max_hp)
