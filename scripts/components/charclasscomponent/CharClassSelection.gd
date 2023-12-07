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


@onready var available_list: ItemList = $AvailableClasses
@onready var owned_list: ItemList = $OwnedClasses
@onready var statsDisplay: Control = $StatDisplay
@onready var classDesc: RichTextLabel = $ClassDescription
@onready var lockedText: Label = $LockedText
@onready var doneButton: Button = $Done

func _ready() -> void:
	assert(not G.is_server(), "The server should not be creating UI elements on it's end.")
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	#Activation of a list's element
	available_list.item_activated.connect(_on_available_activated)
	owned_list.item_activated.connect(_on_owned_activated)
	
	#Selection of a list's element
	available_list.item_selected.connect(_on_available_selected)
	owned_list.item_selected.connect(_on_owned_selected)	

	#Close button
	doneButton.pressed.connect(close)

	statsDisplay.accept_input = false
	
	#Sync changes to server on a timer
	syncTimer.timeout.connect(_on_sync_timer_timeout)
	add_child(syncTimer)
	syncTimer.start(1)
	
	if not class_component:
		GodotLogger.warn("No target has been selected. Make sure to run select_target before anything is attempted.")
		return

	
func select_target(class_comp: CharacterClassComponent):
	if not is_node_ready():
		await ready
		
	class_component = class_comp
	statsDisplay.stats = class_component.stats_component
	
	lockedText.visible = class_component.class_change_locked
	class_component.class_lock_changed.connect(_on_class_lock_changed)
	
	populate_available_list()
	populate_owned_list()
	
	
func populate_available_list():
	#if not class_component:
		#GodotLogger.warn("No target has been selected. Cannot list available classes.")
		#return
		
	available_list.clear()
	
	update_allowed_classes()
	
	for charclass in J.charclass_resources:
		var characterClass: CharacterClassResource = J.charclass_resources[charclass].duplicate()
		
		available_list.add_item(characterClass.displayed_name, characterClass.get_icon())
		available_list.set_item_metadata(available_list.item_count-1, characterClass.class_registered)
		print("Put {0} class in index {1} of the available list".format([characterClass.class_registered, str(available_list.item_count-1)]))
		
	update_available_list()

func populate_owned_list():
	#if not class_component:
		#GodotLogger.warn("No target has been selected. Cannot list available classes.")
		#return
	owned_list.clear()

	for characterClass in class_component.classes:	
		owned_list.add_item(characterClass.displayed_name, characterClass.get_icon())
		owned_list.set_item_metadata(owned_list.item_count-1, characterClass.class_registered)
		print("Put {0} class in index {1} of the owned list".format([characterClass.class_registered, str(owned_list.item_count-1)]))
		
	update_owned_list()

# Update methods are more lightweight than the "populate_" ones and can be used more freely
# Simply cause visual updates
func update_available_list(): 
	if class_component.is_full():
		for idx in available_list.item_count:
			available_list.set_item_disabled(idx, true)
	else:
		for idx in available_list.item_count:
			available_list.set_item_disabled(idx, false)
		
func update_owned_list():
	owned_list.max_columns = class_component.max_classes
	statsDisplay.renew_values.call_deferred()
	
func update_lists():
	update_available_list()
	update_owned_list()

func update_allowed_classes():
	allowed_classes.assign( J.charclass_resources.keys().filter( class_component.is_class_allowed ) ) 


#Signal targets
func _on_available_activated(idx: int):
	if class_component.class_change_locked:
		return
	
	var charClass: String = available_list.get_item_metadata(idx)
	#var charClassRes: CharacterClassResource = J.charclass_resources[charClass]
	
	class_component.add_class(charClass)
	
	populate_owned_list()
	update_lists()
	sync_required = true
	
func _on_owned_activated(idx: int):
	if class_component.class_change_locked:
		return
	
	var charClass: String = available_list.get_item_metadata(idx)
	
	class_component.remove_class(charClass)
	
	populate_owned_list()
	update_lists()
	sync_required = true

func _on_owned_selected(idx: int):
	var charClass:String = owned_list.get_item_metadata(idx)
	var charClassRes:CharacterClassResource = J.charclass_resources[charClass].duplicate()
	
	var text: String = "[bold]{0}[/bold] \n {1}".format([charClassRes.displayed_name,charClassRes.description])
	classDesc.parse_bbcode(text)
	
func _on_available_selected(idx: int):
	var charClass:String = available_list.get_item_metadata(idx)
	var charClassRes:CharacterClassResource = J.charclass_resources[charClass].duplicate()
	
	var text: String = "[bold]{0}[/bold] \n {1}".format([charClassRes.displayed_name,charClassRes.description])
	classDesc.parse_bbcode(text)

func _on_sync_timer_timeout():
	if sync_required and class_component:
		class_component.client_class_change_attempt()
		sync_required = false

func _on_class_lock_changed():
	lockedText.visible = class_component.class_change_locked
		

func close():
	if is_inside_tree():
		get_parent().remove_child(self)

func _on_mouse_entered():
	JUI.above_ui = true

func _on_mouse_exited():
	JUI.above_ui = false

## Should the UI quit early with a sync queued, the change attempt will be deferred instantly.
func _notification(what: int):
	if (what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE) and sync_required and class_component:
		class_component.client_class_change_attempt.call_deferred()
		
