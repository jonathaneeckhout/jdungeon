extends Control


func set_new_name(new_name: String):
	$Name.text = new_name


func update_hp_bar(hp: int, max_hp: int):
	$HPBar.value = float(hp * 100 / max_hp)
