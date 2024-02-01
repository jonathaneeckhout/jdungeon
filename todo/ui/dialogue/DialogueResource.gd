extends Resource
class_name DialogueResource
## This class works by having an [int] to identify each speaker.
## As such, both speaker_names and speaker_portraits must have the same amount of elements.
## So when someone refers to speaker 0, it takes [member speaker_names][0] and [member speaker_portraits][0]
## [member speaker_portaits] contains nested Arrays as to hold several portaits per speaker.

const FAILSAFE_TEXTURE: Texture = preload("res://icon.svg")

@export var dialogue_identifier: String = "UNDEFINED"

@export var speaker_names: Array[String] = ["Spaker One"]

## The later Array contains strings as paths to textures.
@export var speaker_portraits: Array[Array] = [
	["res://assets/images/enemies/flower/original/Flower_head.png"]
]

## Snippets are executed in order, if one is set to not be shown, then it is skipped as if it didn't exist.
@export var dialogue_snippets: Array[DialogueSnippetResource]


func _init() -> void:
	if speaker_portraits.size() != speaker_names.size():
		GodotLogger.warn("Dialogue Array size mismatch")


func get_speaker_name(id: int) -> String:
	if abs(id) >= speaker_names.size():
		(
			GodotLogger
			. warn("Speaker ID {0} out of range. There's {1} speakers in this dialogue.")
			. format([str(id), str(speaker_names.size())])
		)
		return ""
	else:
		return speaker_names[id]


func get_speaker_portrait(id: int, portraitID: int) -> Texture:
	if abs(id) >= speaker_portraits.size():
		(
			GodotLogger
			. warn("Speaker ID {0} out of range. There's {1} speakers in this dialogue.")
			. format([str(id), str(speaker_portraits.size())])
		)
		return FAILSAFE_TEXTURE

	if abs(portraitID) >= speaker_portraits.size():
		(
			GodotLogger
			. warn("Portrait ID {0} out of range. There's {1} speakers in this dialogue.")
			. format([str(portraitID), str(speaker_portraits[id].size())])
		)
		return FAILSAFE_TEXTURE

	var portrait: Texture = load(speaker_portraits[id][portraitID])
	if portrait is Texture:
		return portrait
	else:
		GodotLogger.error("Could not load the portrait {0} for speaker {1}").format(
			[str(portraitID), str(id)]
		)
		return FAILSAFE_TEXTURE


func get_snippets_to_show(trueConditions: Dictionary) -> Array[DialogueSnippetResource]:
	var output: Array[DialogueSnippetResource] = []

	for snippet: DialogueSnippetResource in dialogue_snippets:
		if should_snippet_be_shown(snippet, trueConditions):
			output.append(snippet)

	return output


func should_snippet_be_shown(snippet: DialogueSnippetResource, trueConditions: Dictionary) -> bool:
	#All of the conditions_to_show must be met
	if (
		not snippet.conditions_to_show.is_empty()
		and not trueConditions.has_all(snippet.conditions_to_show)
	):
		return false

	#If ALL conditions_to_hide are true, do not show.
	if (
		not snippet.conditions_to_hide.is_empty()
		and trueConditions.has_all(snippet.conditions_to_hide)
	):
		return false

	return true
