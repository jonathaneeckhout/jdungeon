extends Node
class_name DialogueSystem
## Call [method load_dialogue] to start. Then call [method show_next_snippet] to advance trough each snippet of the dialogue.
## Use [method DialogueSystem.create_dialogue_box] to get an instance of the DialogueBox.tscn scene ready for use.

const FALLBACK_DIALOGUE_IDENTIFIER: String = "FALLBACK"

signal snippet_finished(snippet: DialogueSnippetResource)

signal dialogue_started
signal dialogue_finished

signal dialogue_text_changed(newText: String)
signal dialogue_speaker_changed(newSpeaker: String)
signal dialogue_portrait_changed(newPortrait: Texture)

#Nodes
@export var rich_label_dialogue: RichTextLabel

## Used to set the time required for the text to finish appearing, if you want to modify the speed of individual text snippets. Modify [member DialogueSnippetResource.text_speed_multiplier]
@export var letters_per_second: int = 12

@export var accept_input: bool = false:
	set(val):
		accept_input = val
		set_process_input(accept_input)

## Holds pairs of String:bool values that keep track of what has happened, used to decide what dialogue should be shown.
var dialogue_flags: Dictionary

var current_dialogue: DialogueResource
var current_snippets: Array[DialogueSnippetResource]

var dialogueIndexProgress: int:
	set(val):
		assert(sign(val) >= 0, "Progress should not be negative")
		
		dialogueIndexProgress = val
		
		
var dialogueSize: int
var currentTextTween: Tween

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("j_continue"):
		show_next_snippet()
		
## Can be used statically to load current flags from any other script, using [method DialogueSystem.load_flags]
func load_flags(flags: Dictionary):
	assert(flags.is_empty() or flags[flags.keys()[0]] is bool, "The first element of the flags is not a String:bool pair.")
	dialogue_flags = flags

func create_dialogue_box() -> Control:
	#Due to the tscn file constantly getting corrupted for no reason, i am making the scene manually
	var dialogueBox := Control.new()
	dialogueBox.anchors_preset = 15
	dialogueBox.anchor_right = 1.0
	dialogueBox.anchor_bottom = 1.0
	dialogueBox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialogueBox.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var portrait := TextureRect.new()
	portrait.anchors_preset = -1
	portrait.anchor_right = 0.2
	portrait.anchor_bottom = 0.2
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var speaker := Label.new()
	speaker.anchor_left = 0.2
	speaker.anchors_preset = -1
	speaker.anchor_right = 1.0
	speaker.anchor_bottom = 0.2
	speaker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	speaker.grow_vertical = Control.GROW_DIRECTION_BEGIN
	speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speaker.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	var box := RichTextLabel.new()
	box.anchors_preset = -1
	box.anchor_top = 0.2
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	
	dialogueBox.add_child(portrait)
	dialogueBox.add_child(box)
	dialogueBox.add_child(speaker)
	
	#Connect the nodes to this system
	dialogue_speaker_changed.connect(speaker.set_text)
	dialogue_portrait_changed.connect(portrait.set_texture)
	rich_label_dialogue = box
		
	return dialogueBox
	
static func get_system_from_dialogue_box(dialogueBox: Control) -> DialogueSystem:
	return dialogueBox.get_node("DialogueSystem")

func load_dialogue(dialogueRes: DialogueResource):
	dialogueIndexProgress = 0
	current_dialogue = dialogueRes
	current_snippets = current_dialogue.get_snippets_to_show(dialogue_flags)

func unload_dialogue():
	dialogueIndexProgress = 0
	current_dialogue = null
	current_snippets.clear()
	dialogue_finished.emit()

func show_next_snippet():
	#Stop if there's nothing to show.
	if current_snippets.is_empty():
		if Global.debug_mode:
			GodotLogger.warn("Cannot show snippets, there's none loaded.")
		return
		
	#If this is the first snippet, emit that it has started.
	if dialogueIndexProgress == 0:
		dialogue_started.emit()
		
	#If it's not the first one, mark the previous snippet as seen.
	else:
		process_seen_snippet_flags(current_snippets[dialogueIndexProgress-1])
	
	#If reached the end, finish this dialogue.
	if dialogueIndexProgress >= current_snippets.size():
		unload_dialogue()
		return
	
	var snippetToShow: DialogueSnippetResource = current_snippets[dialogueIndexProgress]
	display_snipet(current_dialogue, snippetToShow)
	
	dialogueIndexProgress += 1
	
	
func display_snipet(dialogueResource: DialogueResource, snippet: DialogueSnippetResource):
	#Cannot display a snippet without a RichTextLabel to put it in.
	if not rich_label_dialogue:
		GodotLogger.warn("No 'rich_text_label' has been set for the dialogue.")
		return
	
	#Set weather or not to use BB Code
	rich_label_dialogue.bbcode_enabled = snippet.enableBBCode
	
	#Load text
	if rich_label_dialogue.bbcode_enabled:
		rich_label_dialogue.parse_bbcode(snippet.text)
	else:
		rich_label_dialogue.text = snippet.text
	dialogueSize = rich_label_dialogue.text.length()
	
	#Emit the change in name and portrait
	dialogue_portrait_changed.emit(dialogueResource.get_speaker_portrait(snippet.speaker_id, snippet.portrait_id))
	dialogue_speaker_changed.emit(dialogueResource.get_speaker_name(snippet.speaker_id))
	
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
		(dialogueSize / letters_per_second) * speedModifier
		)
	currentTextTween.play()

func text_tween_stop():
	if currentTextTween != null:
		currentTextTween.kill()
		currentTextTween = null
	
func is_text_scrolling() -> bool:
	return currentTextTween.is_running()

## Snippets may hold their own flags which can be used to know which ones the player has seen
func process_seen_snippet_flags(snippet: DialogueSnippetResource):
	for flag: String in snippet.flags_set_on_seen:
		dialogue_flags[flag] = true
		
	for flag: String in snippet.flags_unset_on_seen:
		dialogue_flags[flag] = false
