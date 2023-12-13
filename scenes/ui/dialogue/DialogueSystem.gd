extends Node
class_name DialogueSystem
## Call [method load_dialogue] to start. Then call [method show_next_snippet] to advance trough each snippet of the dialogue.
## Use [method DialogueSystem.create_dialogue_box] to get an instance of the DialogueBox.tscn scene ready for use.

const DIALOGUE_BOX_SCENE: PackedScene = preload("res://scenes/ui/dialogue/DialogueBox.tscn")

signal dialogue_started
signal dialogue_finished

#Nodes
@export var sprite_portrait: TextureRect
@export var label_speaker_name: Label
@export var rich_label_dialogue: RichTextLabel

## Used to set the time required for the text to finish appearing, if you want to modify the speed of individual text snippets. Modify [member DialogueSnippetResource.text_speed_multiplier]
@export var letters_per_second: int = 12

@export var accept_input: bool = false:
	set(val):
		accept_input = val
		set_process_input(accept_input)

## Holds pairs of String:bool values that keep track of what has happened, used to decide what dialogue should be shown.
static var dialogue_flags: Dictionary

var current_dialogue: DialogueResource
var current_snippets: Array[DialogueSnippetResource]

var dialogueIndexProgress: int:
	set(val):
		assert(sign(val) > 0, "Progress should not be negative")
		dialogueIndexProgress = val
		
var dialogueSize: int
var currentTextTween: Tween

func _ready() -> void:
	if not (rich_label_dialogue and sprite_portrait):
		GodotLogger.error("Not all nodes have been set for this dialogue system.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("j_continue"):
		show_next_snippet()
		
## Can be used statically to load current flags from any other script, using [method DialogueSystem.load_flags]
static func load_flags(flags: Dictionary):
	assert(flags.is_empty() or flags[flags.keys()[0]] is bool, "The first element of the flags is not a String:bool pair.")
	dialogue_flags = flags

static func create_dialogue_box(dialogueToLoad: DialogueResource = null) -> Control:
	var dialogueBox: Control = DIALOGUE_BOX_SCENE.instantiate()
	if dialogueToLoad is DialogueResource:
		dialogueBox.get_node("DialogueSystem").load_dialogue(dialogueToLoad)
		
	return dialogueBox

func load_dialogue(dialogueRes: DialogueResource):
	dialogueIndexProgress = 0
	current_dialogue = dialogueRes
	current_snippets = current_dialogue.get_snippets_to_show(dialogue_flags)
	show_next_snippet()

func unload_dialogue():
	dialogueIndexProgress = 0
	current_dialogue = null
	current_snippets.clear()

func show_next_snippet():
	#Stop if there's nothing to show.
	if current_snippets.is_empty():
		if Global.debug_mode:
			GodotLogger.warn("Cannot show snippets, there's none loaded.")
		return
		
	#If this is the first snippet, emit that it has started.
	if dialogueIndexProgress == 0:
		dialogue_started.emit()
	
	#If reached the end, finish this dialogue.
	if dialogueIndexProgress >= current_snippets.size():
		dialogue_finished.emit()
		unload_dialogue()
		return
	
	var snippetToShow: DialogueSnippetResource = current_snippets[dialogueIndexProgress]
	display_snipet(current_dialogue, snippetToShow)
	
	
func display_snipet(dialogueResource: DialogueResource, snippet: DialogueSnippetResource):
	#Set weather or not to use BB Code
	rich_label_dialogue.bbcode_enabled = snippet.enableBBCode
	
	#Load text
	if rich_label_dialogue.bbcode_enabled:
		rich_label_dialogue.parse_bbcode(snippet.text)
	else:
		rich_label_dialogue.text = snippet.text
	dialogueSize = rich_label_dialogue.text.length()
	
	#Set the name and portrait
	sprite_portrait.texture = dialogueResource.get_speaker_portrait(snippet.speaker_id, snippet.portrait_id)
	label_speaker_name.text = dialogueResource.get_speaker_name(snippet.speaker_id)
	
	#Prepare to gradually show text or to dump it instantly
	if snippet.text_speed_modifier <= 0:
		rich_label_dialogue.visible_characters = -1
	else:
		rich_label_dialogue.visible_characters = 0
		text_tween_start(snippet.text_speed_modifier)

func text_tween_start(speedModifier: float):
	text_tween_stop()
	
	currentTextTween = create_tween()
	currentTextTween.tween_property(
		rich_label_dialogue, 
		"visible_characters", 
		dialogueSize, 
		dialogueSize / letters_per_second
		)
	currentTextTween.play()

func text_tween_stop():
	if currentTextTween != null:
		currentTextTween.kill()
		currentTextTween = null
	
func is_text_scrolling() -> bool:
	return currentTextTween.is_running()

func _on_dialogue_started():
	rich_label_dialogue.show()
	sprite_portrait.show()
	
func _on_dialogue_finished():
	rich_label_dialogue.hide()
	sprite_portrait.hide()
