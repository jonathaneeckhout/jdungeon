extends Resource
class_name DialogueSnippetResource
## This class is only meant to be used by [DialogueResource]

## The actual text displayed
@export_multiline var text: String = "Undefined dialogue snippet!"

## If true, it makes the [DialogueSystem] use BBCode, otherwise metatags like [ b ] won't work.
## Altho it will improve performance.
@export var enableBBCode: bool = true

## The ID of who is speaking, as defined in [member DialogueResource.speaker_names]
@export var speaker_id: int

## Chooses the variation of the portrait for the chosen speaker
@export var portrait_id: int

## Identifiers that will be provided by DialogueSystem and will decide if this snippet is shown, this requires all conditions to be true.
@export var conditions_to_show: Array[String]

## The opposite of [member show_condition], all of them must be true to not show the snippet.
@export var conditions_to_hide: Array[String]

## A direct modifier to text scroll speed, set to 0 or lower for instant text.
@export var text_speed_modifier: float = 1

## When a player sees this snippet, the following flags are set
@export var flags_set_on_seen: Array[String]

## Opposite as [member flags_set_on_seen]
@export var flags_unset_on_seen: Array[String]
