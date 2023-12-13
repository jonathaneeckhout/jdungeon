extends Node
class_name DialogueSynhcronizerComponent
## This component is merely an intermediary for the [DialogueSystem] class
## Unlike other components, dialogues are invoked autonomously by the server when the player triggers one.

@export var dialogue_box_top_anchor: float = 0.65

@export var user: Player

var accepting_input: bool = false:
	set(val):
		accepting_input = val
		set_process_input(accepting_input)


## The node that will display the dialogue
var dialogueBox: Control

## The DialogueSystem that will be used, part of the dialogueBox scene
var systemInstance := DialogueSystem.new()

func _ready() -> void:
	if not G.is_server():
		return
		
	dialogueBox = systemInstance.create_dialogue_box()
	dialogueBox.anchor_top = dialogue_box_top_anchor
	systemInstance.dialogue_finished.connect(_on_dialogue_finished)
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("continue"):
		systemInstance.show_next_snippet()
	
	
#Called on server only
func sync_invoke(id: int, dialogueIdentifier: String):
	assert(G.is_server(), "Only the server can invoke dialogue.")
	G.sync_rpc.dialoguesynchronizer_sync_invoke_response.rpc_id(id, dialogueIdentifier)


#Called on client only
func sync_invoke_response(dialogueIdentifier: String):
	assert(dialogueBox.get_parent() == null or dialogueBox.get_parent() == user.ui_control)
	
	show_dialogue()
	var dialogueRes: DialogueResource = J.dialogue_resources.get(dialogueIdentifier, null).duplicate()
	
	if dialogueRes == null:
		GodotLogger.error(
			"Could not find dialogue with identifier '{0}'".format([dialogueIdentifier])
		)
		return
	
	systemInstance.load_dialogue(dialogueRes)
	systemInstance.show_next_snippet()
	
	
func show_dialogue():
	if not dialogueBox.is_inside_tree():
		user.ui_control.add_child(dialogueBox)
	
	dialogueBox.anchor_top = dialogue_box_top_anchor
	accepting_input = true
	

func hide_dialogue():
	if dialogueBox.is_inside_tree():
		dialogueBox.get_parent().remove_child(dialogueBox)
		
	accepting_input = false
	

func _on_dialogue_finished():
	hide_dialogue()
