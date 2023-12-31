extends Control
class_name CharacterClassSelectionMenu
## Call [method select_target] to start.

@export var class_component: CharacterClassComponent

## These are the classes that will be presented to the player as available. Updated from [method update_allowed_classes]
var allowed_classes: Array[String]

## Used to know when a synch is required on the next timeout.
var sync_required: bool

## Internally used to queue syncs with the server.
var syncTimer := Timer.new()

var charClassRegisteredNameAvailable: Dictionary
var charClassRegisteredNameOwned: Dictionary

@onready var available_list: GridContainer = $AvailableClasses
@onready var owned_list: GridContainer = $OwnedClasses
@onready var statsDisplay: Control = $StatDisplay
@onready var classDesc: RichTextLabel = $ClassDescription
@onready var lockedText: Label = $LockedText
@onready var doneButton: Button = $Done
@onready var change_skill_button: Button = $ChangeSkills


func _ready() -> void:
	assert(not G.is_server(), "The server should not be creating UI elements on it's end.")

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	change_skill_button.pressed.connect(_on_change_skills_pressed)

	#Close button
	doneButton.pressed.connect(close)
	statsDisplay.accept_input = false

	#Sync changes to server on a timer
	syncTimer.timeout.connect(_on_sync_timer_timeout)
	add_child(syncTimer)
	syncTimer.start(1)


func select_target(class_comp: CharacterClassComponent):
	if not is_node_ready():
		await ready

	class_component = class_comp
	statsDisplay.stats = class_component.stats_component

	lockedText.visible = not class_component.is_class_change_allowed()
	class_component.class_lock_changed.connect(_on_class_lock_changed)

	populate_available_list()
	populate_owned_list()


func populate_available_list():
	if not class_component:
		GodotLogger.warn("No target has been selected. Cannot list available classes.")
		return

	for child in available_list.get_children():
		child.queue_free()

	update_allowed_classes()

	for charclass in J.charclass_resources:
		var characterClass: CharacterClassResource = J.charclass_resources[charclass].duplicate()

		var menuElement := CharacterClassMenuElement.new(
			characterClass.class_registered,
			characterClass.displayed_name,
			characterClass.get_icon()
		)

		available_list.add_child(menuElement)
		menuElement.self_hovered.connect(_on_available_selected)
		menuElement.self_pressed.connect(_on_available_activated)

	update_available_list()


func populate_owned_list():
	if not class_component:
		GodotLogger.warn("No target has been selected. Cannot list available classes.")
		return

	for child in owned_list.get_children():
		child.queue_free()

	for characterClass in class_component.classes:
		var menuElement := CharacterClassMenuElement.new(
			characterClass.class_registered,
			characterClass.displayed_name,
			characterClass.get_icon()
		)

		owned_list.add_child(menuElement)
		menuElement.self_hovered.connect(_on_owned_selected)
		menuElement.self_pressed.connect(_on_owned_activated)

	update_owned_list()


# Update methods are more lightweight than the "populate_" ones and can be used more freely
# Simply cause visual updates
func update_available_list():
	#Disable if the player is not allowed to change or add classes
	if class_component.is_full() or not class_component.is_class_change_allowed():
		for child in available_list.get_children():
			if child is Button:
				child.disabled = true

	#Enable otherwise
	else:
		for child in available_list.get_children():
			if child is Button:
				child.disabled = false


func update_owned_list():
	owned_list.columns = class_component.max_classes
	statsDisplay.renew_values.call_deferred()


func update_lists():
	update_available_list()
	update_owned_list()


func update_allowed_classes():
	allowed_classes.assign(J.charclass_resources.keys().filter(class_component.is_class_allowed))


#Signal targets
func _on_available_activated(element: CharacterClassMenuElement):
	if class_component.class_change_locked:
		return

	var charClass: String = element.char_class

	class_component.add_class(charClass)

	populate_owned_list()
	update_lists()
	sync_required = true


func _on_owned_activated(element: CharacterClassMenuElement):
	if class_component.class_change_locked:
		return

	var charClass: String = element.char_class

	class_component.remove_class(charClass)

	populate_owned_list()
	update_lists()
	sync_required = true


func _on_owned_selected(element: CharacterClassMenuElement):
	var charClassRes: CharacterClassResource = J.charclass_resources[element.char_class].duplicate()

	var text: String = "[b]{0}[/b] \n {1}".format(
		[charClassRes.displayed_name, charClassRes.description]
	)
	classDesc.parse_bbcode(text)


func _on_available_selected(element: CharacterClassMenuElement):
	var charClassRes: CharacterClassResource = J.charclass_resources[element.char_class].duplicate()

	var text: String = "[b]{0}[/b] \n {1}".format(
		[charClassRes.displayed_name, charClassRes.description]
	)
	classDesc.parse_bbcode(text)


func _on_sync_timer_timeout():
	if sync_required and class_component:
		class_component.client_class_change_attempt()
		sync_required = false


func _on_class_lock_changed():
	lockedText.visible = not class_component.is_class_change_allowed()
	update_lists()


func close():
	if is_inside_tree():
		get_parent().remove_child(self)
		JUI.above_ui = false


func _on_change_skills_pressed():
	var skillSelection: SkillSelectionUI = SkillSelectionUI.PACKED_SCENE.instantiate()
	skillSelection.select_target(class_component.user)
	add_sibling(skillSelection)
	skillSelection.populate_ui()
	close()


func _on_mouse_entered():
	JUI.above_ui = true


func _on_mouse_exited():
	JUI.above_ui = false


## Should the UI quit early with a sync queued, the change attempt will be deferred instantly.
func _notification(what: int):
	if (
		(what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE)
		and sync_required
		and class_component
	):
		class_component.client_class_change_attempt()


class CharacterClassMenuElement:
	extends Button
	var char_class: String
	signal self_pressed(this: CharacterClassMenuElement)
	signal self_hovered(this: CharacterClassMenuElement)

	func _init(_charClass: String, _classDisplayName: String, _iconTexture: Texture) -> void:
		char_class = _charClass
		icon = _iconTexture
		text = _classDisplayName

		mouse_entered.connect(_on_mouse_entered)

	func _ready() -> void:
		#Do not allow the icon to resize the button
		expand_icon = true

		#Size control
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		offset_bottom = 0
		offset_top = 0
		offset_left = 0
		offset_right = 0

	func _pressed() -> void:
		self_pressed.emit(self)

	func _on_mouse_entered():
		self_hovered.emit(self)
