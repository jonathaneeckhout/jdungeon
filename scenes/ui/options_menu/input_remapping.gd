extends Control
class_name InputRemapping
## Recommended for use in a VBoxContainer
## Fills itself with buttons to remap actions

#Emitted when a button of an event is pressed
signal remap_initiated

#Succis
signal remap_successful

#When cancelled trough the j_toggle_menu
signal remap_aborted

#Emitted regardless of success or failure
signal remap_finished

const BUTTON_ACTIVE_MODULATE: Color = Color.WHITE * 1.5
const Messages: Dictionary = {
	SUCCESSFUL = "Remapping Successful.",
	ABORTED = "Remapping Cancelled.",
	INITIATED = "Press a button.",
	CONFLICT = "This button is mapped."
}

@export var actionsAllowed: Array[StringName] = [
	&"j_toggle_bag", &"j_toggle_equipment", &"j_toggle_stats", &"j_ui_chat_toggle", &"j_ui_toggle"
]
@export var tempTextDuration: float = 2

var currentAction: StringName
var currentEvent: InputEvent
var currentButton: Button


func _ready() -> void:
	update_list()
	remap_initiated.connect(temporary_text_signaled.bind(Messages.INITIATED, remap_finished))
	remap_aborted.connect(temporary_text_timed.bind(Messages.ABORTED, tempTextDuration))
	remap_successful.connect(temporary_text_timed.bind(Messages.SUCCESSFUL, tempTextDuration))

	#This merely sets the mappings on the loaded ConfigFile, it does not write to disk. Making it suitable for repeated use.
	remap_successful.connect(save_mappings)


#Creates text on screen that dissapears after some time or when the signal is called
func temporary_text_timed(tempText: String, duration: float):
	var textLabel := Label.new()
	textLabel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER + Control.SIZE_EXPAND
	textLabel.size_flags_vertical = Control.SIZE_SHRINK_END + Control.SIZE_EXPAND
	#This shifts it upwards a bit. To avoid overlapping with signaled text.
	textLabel.custom_minimum_size = Vector2(0, 96)
	textLabel.text = tempText

	add_sibling(textLabel)

	if duration > 0:
		get_tree().create_timer(duration).timeout.connect(textLabel.queue_free)


func temporary_text_signaled(tempText: String, killSignal: Signal):
	var textLabel := Label.new()
	textLabel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER + Control.SIZE_EXPAND
	textLabel.size_flags_vertical = Control.SIZE_SHRINK_END + Control.SIZE_EXPAND
	textLabel.text = tempText

	add_sibling(textLabel)

	killSignal.connect(textLabel.queue_free)


func update_list():
	#Clear all children
	for child in get_children():
		child.queue_free()

	#Iterate trough each action
	for action in actionsAllowed:
		#Ignore non-existent inputs
		if not action in InputMap.get_actions():
			GodotLogger.error('Cannot list invalid action "{0}"'.format([action]))
			continue

		#Add nodes for each of them
		add_remap_node(action, InputMap.action_get_events(action))


func add_remap_node(action: StringName, events: Array[InputEvent]):
	#Splits the button to the left and actions to the right
	var splitContainer := HSplitContainer.new()
	splitContainer.set_name(action)
	splitContainer.dragger_visibility = SplitContainer.DRAGGER_HIDDEN

	#Displays the name of the action
	var actionNameLabel := Label.new()
	actionNameLabel.set_name("ActionStringName")

	#Lists every event
	var eventContainer := VBoxContainer.new()
	eventContainer.set_name("InputEvents")

	#Add nodes
	add_child(splitContainer)
	splitContainer.add_child(actionNameLabel)
	splitContainer.add_child(eventContainer)

	actionNameLabel.text = action

	for event in events:
		var remapButton := Button.new()
		remapButton.text = event.as_text().replace(" (Physical)", "")
		eventContainer.add_child(remapButton)

		remapButton.pressed.connect(on_remap_attempt.bind(action, event, remapButton))


func on_remap_attempt(action: StringName, event: InputEvent, button: Button):
	currentAction = action
	currentEvent = event
	currentButton = button
	button.modulate = BUTTON_ACTIVE_MODULATE
	remap_initiated.emit()


func is_event_in_use(event: InputEvent) -> bool:
	for action in actionsAllowed:
		if InputMap.action_has_event(action, event):
			return true

	return false


func terminate_remap_attempt():
	currentButton.modulate = Color.WHITE
	currentAction = &""
	currentEvent = null
	currentButton = null
	remap_finished.emit()


func _input(event: InputEvent):
	#If these are not set, abort
	if currentAction.is_empty():
		return
	if currentEvent == null:
		return
	if currentButton == null:
		return

	#A remapping is in progress, prevent the input from reaching outside of this node.
	get_viewport().set_input_as_handled()

	#Cancel if the toggle menu button is pressed.
	if event.is_action(&"j_toggle_game_menu"):
		remap_aborted.emit()
		terminate_remap_attempt()
		return

	#Only accept certain kinds of InputEvent
	if not (
		event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	):
		return
	#There's no controller support yet.

	#Fetch current event count to check for discrepancies later
	var eventCount: int = InputMap.action_get_events(currentAction).size()

	#Ensure it isn't used somewhere else
	if is_event_in_use(event):
		temporary_text_timed(Messages.CONFLICT, tempTextDuration * 0.6)
		return

	#Ensure this event belongs to the action, it should be impossible for this to be the case
	if not InputMap.action_has_event(currentAction, currentEvent):
		push_warning(str(currentEvent) + " does not belong to action " + currentAction)

	#Remove the existing event
	InputMap.action_erase_event(currentAction, currentEvent)

	#Add the event just pressed as the new input
	InputMap.action_add_event(currentAction, event)

	#Make sure it worked.
	if not InputMap.action_has_event(currentAction, event):
		GodotLogger.error("The event was not set.")
	if not InputMap.action_get_events(currentAction).size() == eventCount:
		GodotLogger.error(
			(
				"There's a different amount of events from before the remapping for action "
				+ currentAction
				+ "\n"
				+ "These are assigned now: "
				+ str(InputMap.action_get_events(currentAction))
			)
		)

	#Update the button's text
	currentButton.text = event.as_text()

	GodotLogger.info(
		"Successfully remaped action {0} from event {1} to event {2}".format(
			[currentAction, currentEvent.as_text(), event.as_text()]
		)
	)
	remap_successful.emit()
	terminate_remap_attempt()

	update_list()


func get_mappings_as_dict() -> Dictionary:
	var inputDict: Dictionary = {}
	for action in actionsAllowed:
		inputDict[action] = []
		for event in InputMap.action_get_events(action):
			inputDict[action].append(event)

	return inputDict


func save_mappings():
	LocalSaveSystem.set_data(
		LocalSaveSystem.Sections.SETTINGS, "controlMappings", get_mappings_as_dict()
	)


static func load_mappings():
	var inputDict: Dictionary = LocalSaveSystem.get_data(
		LocalSaveSystem.Sections.SETTINGS, "controlMappings", {}
	)

	if inputDict.is_empty():
		push_warning("No control mapping data was found, the default mappings will be used.")
		return

	for action in inputDict:
		#Wipe existing events from this action
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)

		for event in inputDict[action]:
			InputMap.action_add_event(action, event)
