extends Node
class_name DialogueSynhcronizerComponent
## This component is merely an intermediary for the [DialogueSystem] class
## Unlike other components, dialogues are invoked autonomously by the server when the player triggers one.
## All methods in this component are client-only unless stated otherwise

@export var dialogue_box_top_anchor: float = 0.65
@export var dialogue_box_opacity: float = 0.6

@export var user: Player

var accepting_input: bool = false:
	set(val):
		accepting_input = val
		set_process_input(accepting_input)

## The node that will display the dialogue
var dialogueBox: Control

## The DialogueSystem that will be used
var dialogue_system_instance := DialogueSystem.new()


func _ready() -> void:
	if user.get("component_list") != null:
		user.component_list["dialogue_component"] = self

	if G.is_server():
		return

	dialogueBox = dialogue_system_instance.create_dialogue_box(
		DialogueSystem.DEFAULT_THEME, dialogue_box_opacity
	)
	assert(dialogueBox is Control)
	dialogueBox.anchor_top = dialogue_box_top_anchor
	dialogue_system_instance.dialogue_finished.connect(_on_dialogue_finished)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("j_continue"):
		dialogue_system_instance.show_next_snippet()


#Called by and on server only
func sync_invoke(id: int, dialogueIdentifier: String):
	assert(G.is_server(), "Only the server can invoke dialogue.")
	G.sync_rpc.dialoguesynchronizer_sync_invoke_response.rpc_id(
		id, user.get_name(), dialogueIdentifier
	)


func sync_invoke_response(dialogueIdentifier: String):
	assert(dialogueBox.get_parent() == null or dialogueBox.get_parent() == user.ui_control)

	var dialogueRes: DialogueResource = (
		J.dialogue_resources.get(dialogueIdentifier, null).duplicate()
	)

	if dialogueRes == null:
		GodotLogger.error(
			"Could not find dialogue with identifier '{0}'".format([dialogueIdentifier])
		)
		return

	dialogue_system_instance.load_dialogue(dialogueRes)

	show_dialogue()
	dialogue_system_instance.show_next_snippet()


func show_dialogue():
	if not dialogueBox.is_inside_tree():
		user.ui_control.add_child(dialogueBox)

	assert(dialogueBox.get_parent() == user.ui_control)

	dialogueBox.anchor_top = dialogue_box_top_anchor
	accepting_input = true


func hide_dialogue():
	if dialogueBox.is_inside_tree():
		dialogueBox.get_parent().remove_child(dialogueBox)

	accepting_input = false


func _on_dialogue_finished():
	hide_dialogue()
	G.sync_rpc.dialoguesynchronizer_sync_dialogue_finished.rpc_id(1, user.get_name())
