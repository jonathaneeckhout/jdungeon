extends Control

const OPTIONS_MENU_SCENE: PackedScene = preload("res://scenes/ui/options_menu/options_menu.tscn")
const REPORT_BUG_MENU_SCENE: PackedScene = preload(
	"res://scenes/ui/report_bug_menu/report_bug_menu.tscn"
)

@onready var options_button: Button = $Panel/VBoxContainer/MarginContainer2/OptionsMenu
@onready var report_bug_button: Button = $Panel/VBoxContainer/MarginContainer3/ReportBugMenu
@onready var quit_button: Button = $Panel/VBoxContainer/MarginContainer/QuitButton

@onready var panel: Control = $Panel

#Holds a reference to the currently open sub-menu
var subMenuReference: Node


func _ready():
	quit_button.pressed.connect(_on_quit_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	report_bug_button.pressed.connect(_on_report_bug_button_pressed)


func _input(event):
	if JUI.chat_active:
		return

	var isVisible: bool = self.is_visible_in_tree()

	if event.is_action_pressed("j_toggle_game_menu"):
		print("HIER")

		#Show if not visible, hide otherwise.
		self.visible = not isVisible
		JUI.above_ui = not isVisible

		if not visible:
			close_submenu()

	if isVisible:
		#If the input happens outside the menu while it is open, hide it
		if (event is InputEventMouseButton) and event.pressed:
			var event_local: InputEvent = make_input_local(event)
			var isInsideMenu: bool = (
				Rect2(
					Vector2(panel.position.x, panel.position.y), Vector2(panel.size.x, panel.size.y)
				)
				. has_point(event_local.position)
			)

			#By default say it is inside the submenu
			var isInsideSubMenu: bool = true
			#If a submenu exists, check if it is ACTUALLY inside

			if is_instance_valid(subMenuReference):
				isInsideSubMenu = (
					Rect2(
						Vector2(subMenuReference.position.x, subMenuReference.position.y),
						Vector2(subMenuReference.size.x, subMenuReference.size.y)
					)
					. has_point(event_local.position)
				)

			if not (isInsideMenu or isInsideSubMenu):
				self.hide()
				JUI.above_ui = false

				close_submenu()

				get_viewport().set_input_as_handled()


#Also saves changes to disk.
func close_submenu():
	LocalSaveSystem.save_file()

	if is_instance_valid(subMenuReference):
		subMenuReference.queue_free()


func _on_options_button_pressed():
	var optionsInstance: Control = OPTIONS_MENU_SCENE.instantiate()
	subMenuReference = optionsInstance
	optionsInstance.quit_pressed.connect(close_submenu)
	add_child(optionsInstance)


func _on_report_bug_button_pressed():
	var reportBugInstance: Control = REPORT_BUG_MENU_SCENE.instantiate()
	subMenuReference = reportBugInstance
	reportBugInstance.quit_pressed.connect(close_submenu)
	add_child(reportBugInstance)


func _on_quit_button_pressed():
	JUI.confirmationbox("Are you sure you want to quit the game?", self, "Quit Game?", quit_game)


func quit_game():
	get_tree().quit()
