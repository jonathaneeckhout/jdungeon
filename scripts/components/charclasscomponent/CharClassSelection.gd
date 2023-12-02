extends Control
## Once [method select_target] is ran, a list will fill with allowed and dissallowed


@export var class_component: CharacterClassComponent

## These are the classes that will be presented to the player as available
@export var allowed_classes: Array[String]


@onready var available_list: ItemList = $AvailableClasses
@onready var owned_list: ItemList = $OwnedClasses
@onready var statsDisplay: Control = $StatDisplay
@onready var classDesc: RichTextLabel = $ClassDescription


func _ready() -> void:
	available_list.item_activated.connect(_on_available_activated)
	owned_list.item_activated.connect(_on_owned_activated)
	
	available_list.item_selected.connect(_on_available_selected)
	owned_list.item_selected.connect(_on_owned_selected)
	
	statsDisplay.accept_input = false
	
	if not class_component:
		GodotLogger.warn("No target has been selected. Make sure to run select_target before anything is attempted.")
		return

	
	
func select_target(class_comp: CharacterClassComponent):
	class_component = class_comp
	statsDisplay.stats = class_component.stats_component
	
	populate_available_list()
	populate_owned_list()
	
	
func populate_available_list():
	#if not class_component:
		#GodotLogger.warn("No target has been selected. Cannot list available classes.")
		#return
		
	available_list.clear()
	
	update_allowed_classes()
	
	var index: int = 0
	for charclass in J.charclass_resources:
		var characterClass: CharacterClassResource = J.charclass_resources[charclass].duplicate()
		
		available_list.add_item(characterClass.displayed_name, characterClass.get_icon())
		available_list.set_item_metadata(index, characterClass.class_registered)
		
		index += 1

func populate_owned_list():
	#if not class_component:
		#GodotLogger.warn("No target has been selected. Cannot list available classes.")
		#return
	owned_list.clear()

	var index: int = 0
	for characterClass in class_component.classes:
		
		available_list.add_item(characterClass.displayed_name, characterClass.get_icon())
		available_list.set_item_metadata(index, characterClass.class_registered)
		index += 1

## More lightweight than [method populate_available_list], simply causes visual updates
func update_available_list(): 
	if class_component.is_full():
		for idx in available_list.item_count:
			available_list.set_item_disabled(idx, true)
	else:
		for idx in available_list.item_count:
			available_list.set_item_disabled(idx, false)
		
func update_owned_list():
	owned_list.max_columns = class_component.max_classes
	statsDisplay.renew_values()
	
func update_lists():
	update_available_list()
	update_owned_list()

func update_allowed_classes():
	allowed_classes = J.charclass_resources.keys()
	
	#Whitelist if present
	if not class_component.class_whitelist.is_empty():
		allowed_classes = allowed_classes.filter( func(charClass: String): return (
			charClass in class_component.class_whitelist
		))
	
	#Blacklist
	allowed_classes = allowed_classes.filter( func(charClass: String): return (
		not charClass in class_component.class_blacklist
	))


#Signal targets
func _on_available_activated(idx: int):
	var charClass: String = available_list.get_item_metadata(idx)
	#var charClassRes: CharacterClassResource = J.charclass_resources[charClass]
	
	class_component.add_class(charClass)
	
	populate_owned_list()
	update_lists()
	
func _on_owned_activated(idx: int):
	var charClass: String = available_list.get_item_metadata(idx)
	
	class_component.remove_class(charClass)
	
	populate_owned_list()
	update_lists()

func _on_owned_selected(idx: int):
	var charClass:String = owned_list.get_item_metadata(idx)
	var charClassRes:CharacterClassResource = J.charclass_resources[charClass].duplicate()
	
	var text: String = "[bold]{0}[/bold] \n {1}"
	classDesc.parse_bbcode(text)
	
func _on_available_selected(idx: int):
	var charClass:String = available_list.get_item_metadata(idx)
	var charClassRes:CharacterClassResource = J.charclass_resources[charClass].duplicate()
	
	var text: String = "[bold]{0}[/bold] \n {1}"
	classDesc.parse_bbcode(text)

	
	
