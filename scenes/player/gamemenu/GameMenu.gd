extends PanelContainer

class_name GameMenu

const CONTROLS_MENU_SCENE: PackedScene = preload(
	"res://scenes/player/gamemenu/controlsmenu/ControlsMenu.tscn"
)
const REPORT_BUG_MENU_SCENE: PackedScene = preload(
	"res://scenes/player/gamemenu/reportbugmenu/ReportBugMenu.tscn"
)

@export var player_unstuck: PlayerUnstuckComponent = null

@onready var controls_button: Button = %ControlsButton
@onready var report_bug_button: Button = %ReportBugButton
@onready var quit_button: Button = %QuitButton
@onready var unstuck_button: Button = %UnstuckButton

# @onready var panel: Control = $Panel

# #Holds a reference to the currently open sub-menu
var sub_menu_reference: Node


func _ready():
	controls_button.pressed.connect(_on_controls_button_pressed)
	report_bug_button.pressed.connect(_on_report_bug_button_pressed)
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


#Also saves changes to disk.
func close_submenu():
	LocalSaveSystem.save_file()

	if is_instance_valid(sub_menu_reference):
		sub_menu_reference.queue_free()


func _on_controls_button_pressed():
	var controls_instance: Control = CONTROLS_MENU_SCENE.instantiate()
	sub_menu_reference = controls_instance
	controls_instance.quit_pressed.connect(close_submenu)
	add_child(controls_instance)


func _on_report_bug_button_pressed():
	var report_bug_instance: Control = REPORT_BUG_MENU_SCENE.instantiate()
	sub_menu_reference = report_bug_instance
	report_bug_instance.quit_pressed.connect(close_submenu)
	add_child(report_bug_instance)


func _on_unstuck_button_pressed():
	JUI.confirmationbox("You will die and respawn, ok?", self, "Respawn?", unstuck)


func _on_quit_button_pressed():
	JUI.confirmationbox("Are you sure you want to quit the game?", self, "Quit Game?", quit_game)


func unstuck():
	player_unstuck.unstuck()
	self.hide()
	JUI.above_ui = false


func quit_game():
	get_tree().quit()
