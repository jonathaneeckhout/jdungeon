extends Control
class_name InputRemappingUI
##Recommended for use in a VBoxContainer
##Fills itself with buttons to remap actions


const BUTTON_ACTIVE_MODULATE:Color = Color.WHITE * 1.5

#This needs tweaking
@export var actionsAllowed:Array[StringName] = [
#	&"j_left_click",
#	&"j_right_click", 
	&"j_toggle_bag",
	&"j_toggle_equipment",
	]
@export var maxEventsPerAction:int = 1

var currentAction:StringName
var currentEvent:InputEvent
var currentButton:Button

func _ready() -> void:
	update_list()
	
func update_list():
	#Clear all children
	for child in get_children(): child.queue_free
	
	#Iterate trough each action
	for action in actionsAllowed:
		
		#Ignore inexistent inputs
		if not action in InputMap.get_actions():
			push_error('Cannot list invalid action "{0}"'.format([action]))
			continue
		
		#Add nodes for each of them
		add_remap_node(action, InputMap.action_get_events(action))
			
	
func add_remap_node(action:StringName, events:Array[InputEvent]):
	#Splits the button to the left and actions to the right
	var splitContainer:=HSplitContainer.new()
	splitContainer.set_name(action)
	
	#Displays the name of the action
	var actionNameLabel:=Label.new()
	actionNameLabel.set_name("ActionStringName")
	
	#Lists every event
	var eventContainer:=VBoxContainer.new()
	eventContainer.set_name("InputEvents")
	
	#Add nodes
	add_child(splitContainer)
	splitContainer.add_child(actionNameLabel)
	splitContainer.add_child(eventContainer)
	
	actionNameLabel.text = action
	
	var eventCount:int = 0
	for event in events:
		#Stop listing events if there's too many events in the UI already
		if eventCount >= maxEventsPerAction: break
		
		var remapButton:=Button.new()
		remapButton.text = event.as_text()
		eventContainer.add_child(remapButton)
#		remapButton.set_meta(META_KEY_INPUTEVENT, event)
		
		remapButton.pressed.connect(on_remap_attempt.bind(action, event, remapButton))
		
func on_remap_attempt(action:StringName, event:InputEvent, button:Button):
	currentAction = action
	currentEvent = event
	currentButton = button
	button.modulate = BUTTON_ACTIVE_MODULATE
	
	
func terminate_remap_attempt():
	currentButton.modulate = Color.WHITE
	currentAction = &""
	currentEvent = null
	currentButton = null
	
	
func _input(event:InputEvent):
	#If these are not set, abort
	if currentAction.is_empty(): return
	if currentEvent == null: return
	if currentButton == null: return
#	print_debug("Can remap")
	
	#Cancel if the toggle menu button is pressed.
	if event.is_action("j_toggle_game_menu"): 
		print_debug("Aborted remap")
		terminate_remap_attempt()
		return
	
	#Only accept certain kinds of InputEvent
	if not (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton): return
	#There's no controller support yet.
	
	var eventCount:int = InputMap.get_actions().size()
	
	#Remove the one selected
	InputMap.action_erase_event(currentAction, currentEvent)
	
	#Add the event just pressed as the new input
	InputMap.action_add_event(currentAction, event)
	
	#Make sure it worked.
	assert(InputMap.action_has_event(currentAction, event))
	if not InputMap.get_actions().size() == eventCount:
		push_error("There's a different amount of events from before the remapping.")
	
	#Update the button's text
	currentButton.text = event.as_text()
	
	print_debug("Successfully remaped action {0} from event {1} to event {2}".format([currentAction, currentEvent.as_text(), event.as_text()]))
	terminate_remap_attempt()
