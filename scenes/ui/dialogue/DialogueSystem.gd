extends Node
class_name DialogueSystem
## Run [method load_dialogue] to start. Then run [method show_next_snippet] to advance trough each part of the dialogue.

signal dialogue_started
signal dialogue_finished

@export var sprite_portrait: TextureRect
@export var rich_label_dialogue: RichTextLabel

## Used to set the time required for the text to finish appearing
@export var letters_per_second: int = 20

## Holds pairs of String:bool values that determine what has happened, used to decide what dialogue should be shown.
static var dialogue_flags: Dictionary

var current_dialogue: DialogueResource
var current_snippets: Array[DialogueSnippetResource]

var dialogueIndexProgress: int
var dialogueSize: int
var currentTextTween: Tween

func _ready() -> void:
	if not (rich_label_dialogue and sprite_portrait):
		GodotLogger.error("Not all nodes have been set for this dialogue system.")
		
## Can be used statically to load current flags from any other script, using [method DialogueSystem.load_flags]
static func load_flags(flags: Dictionary):
	assert(flags.is_empty() or flags[flags.keys()[0]] is bool, "The first element of the flags is not a String:bool pair.")
	dialogue_flags = flags

func load_dialogue(dialogueRes: DialogueResource):
	dialogueIndexProgress = 0
	current_dialogue = dialogueRes
	current_snippets = current_dialogue.get_snippets_to_show(dialogue_flags)

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
		unload_dialogue()
		dialogue_finished.emit()
		return
	
	var snippetToShow: DialogueSnippetResource = current_snippets[dialogueIndexProgress]
	display_snipet(current_dialogue, snippetToShow)
	
	
func display_snipet(dialogueResource: DialogueResource, snippet: DialogueSnippetResource):
	rich_label_dialogue.bbcode_enabled = snippet.enableBBCode
	#Load text
	if rich_label_dialogue.bbcode_enabled:
		rich_label_dialogue.parse_bbcode(snippet.text)
	else:
		rich_label_dialogue.text = snippet.text
	dialogueSize = rich_label_dialogue.text.length()
	
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
