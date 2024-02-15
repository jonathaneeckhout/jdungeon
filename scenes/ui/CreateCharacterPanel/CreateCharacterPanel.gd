extends Control

class_name CreateCharacterPanel

signal class_selected(class_string: String)


func _ready():
	%SelectWarriorButton.pressed.connect(_on_select_warrior_button)
	%SelectRangerButton.pressed.connect(_on_select_ranger_button)
	%SelectWizardButton.pressed.connect(_on_select_wizard_button)


func _on_select_warrior_button():
	JUI.confirmationbox("You want to become a warrior?", self, "Are you sure?", _select_warrior)


func _on_select_ranger_button():
	JUI.confirmationbox("You want to become a Ranger?", self, "Are you sure?", _select_ranger)


func _on_select_wizard_button():
	JUI.confirmationbox(
		"You want to become a warWizardrior?", self, "Are you sure?", _select_wizard
	)


func _select_warrior():
	class_selected.emit("Warrior")


func _select_ranger():
	class_selected.emit("Ranger")


func _select_wizard():
	class_selected.emit("Wizard")
