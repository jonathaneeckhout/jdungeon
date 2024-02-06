extends PanelContainer

# const OPTIONS_MENU_SCENE: PackedScene = preload("res://scenes/ui/options_menu/options_menu.tscn")
# const REPORT_BUG_MENU_SCENE: PackedScene = preload(
# 	"res://scenes/ui/report_bug_menu/report_bug_menu.tscn"
# )

@export var player_unstuck: PlayerUnstuckComponent = null

# @onready var options_button: Button = $Panel/VBoxContainer/OptionsMarginContainer/OptionsMenu
@onready var report_bug_button: Button = %ReportBugButton
@onready var quit_button: Button = %QuitButton
@onready var unstuck_button: Button = %UnstuckButton

# @onready var panel: Control = $Panel

# #Holds a reference to the currently open sub-menu
# var subMenuReference: Node


func _ready():
	#options_button.pressed.connect(_on_options_button_pressed)
	#report_bug_button.pressed.connect(_on_report_bug_button_pressed)
	unstuck_button.pressed.connect(_on_unstuck_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _input(event):
	if JUI.chat_active:
		return

	if event.is_action_pressed("j_toggle_game_menu"):
		#Show if not visible, hide otherwise.
		self.visible = not self.visible
		JUI.above_ui = not self.visible

	if self.visible:
		#If the input happens outside the menu while it is open, hide it
		if (event is InputEventMouseButton) and event.pressed:
			var is_inside_menu: bool = (
				Rect2(Vector2(position.x, position.y), Vector2(size.x, size.y))
				. has_point(event.position)
			)

			if not is_inside_menu:
				self.hide()
				JUI.above_ui = false

				get_viewport().set_input_as_handled()


# #Also saves changes to disk.
# func close_submenu():
# 	LocalSaveSystem.save_file()

# 	if is_instance_valid(subMenuReference):
# 		subMenuReference.queue_free()

# func _on_options_button_pressed():
# 	var optionsInstance: Control = OPTIONS_MENU_SCENE.instantiate()
# 	subMenuReference = optionsInstance
# 	optionsInstance.quit_pressed.connect(close_submenu)
# 	add_child(optionsInstance)

# func _on_report_bug_button_pressed():
# 	var reportBugInstance: Control = REPORT_BUG_MENU_SCENE.instantiate()
# 	subMenuReference = reportBugInstance
# 	reportBugInstance.quit_pressed.connect(close_submenu)
# 	add_child(reportBugInstance)


func _on_unstuck_button_pressed():
	print("HIER")
	JUI.confirmationbox("You will die and respawn, ok?", self, "Respawn?", unstuck)


func _on_quit_button_pressed():
	JUI.confirmationbox("Are you sure you want to quit the game?", self, "Quit Game?", quit_game)


func unstuck():
	player_unstuck.unstuck()
	self.hide()
	JUI.above_ui = false


func quit_game():
	get_tree().quit()
