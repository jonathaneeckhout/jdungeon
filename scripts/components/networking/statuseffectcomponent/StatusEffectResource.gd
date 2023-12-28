extends Resource
class_name StatusEffectResource
## Uses a factor pattern for quick customization.
## Example:
##	var newStatus := StatusEffectResource.new().set_owner(self).set_duration(3.5)

enum Types { POSITIVE, NEGATIVE, NEUTRAL }

const FALLBACK_TEXTURE: Texture = preload("res://icon.svg")

@export var status_class: String
@export var displayed_name: String = "Unnamed Status"
@export_multiline var description: String
@export_file("*.jpg *.png *.svg") var icon_path: String = "res://icon.svg"

@export var type: Types

@export_group("Timeout Behaviour")
## How many stacks are removed per timeout (flat amount)
@export var timeout_satck_consumption_flat: int = 0
## The percentage of stacks that are consumed every timeout, applies before [member timeout_satck_consumption_flat].
## A value of 0.5 would remove half of the stacks, 1.0 removes all of them.
@export_range(0, 1.0, 0.01) var timeout_stack_consumption_percent: float = 1.0

## Combine Behaviour refers to what happens when a status effect is already present in the component.
@export_group("Combine Behaviour", "combine")
## The duration of this status and the combined status will be added togheter instead of choosing the highest of the two.
@export var combine_stackable_duration: bool = false
## Stacks will not be added togheter, but instead the highest amount of the two statuses will be chosen.
@export var combine_stack_override: bool = true

@export_group("Defaults", "default")
@export var default_stacks: int = 1
@export var default_duration: float = 1.0

## Used to keep track of the stat boost that this status effect caused, if any.
var boost_reference: Boost


## [param _json_data] contains a "applier" (String), "stacks" (int), "duration" (float) entries.
func effect_applied(target: Node, json_data: Dictionary):
	_effect_applied(target, json_data)


func _effect_applied(_target: Node, _json_data: Dictionary):
	pass


func effect_tick(target: Node, json_data: Dictionary):
	_effect_tick(target, json_data)


func _effect_tick(_target: Node, _json_data: Dictionary):
	pass


func effect_stack_change(target: Node, json_data: Dictionary):
	_effect_stack_change(target, json_data)


func _effect_stack_change(_target: Node, _json_data: Dictionary):
	pass


func effect_timeout(target: Node, json_data: Dictionary):
	_effect_timeout(target, json_data)


func _effect_timeout(_target: Node, _json_data: Dictionary):
	pass


func effect_removed(target: Node, json_data: Dictionary):
	_effect_removed(target, json_data)


func _effect_removed(_target: Node, _json_data: Dictionary):
	pass


## May be overriden
func get_description() -> String:
	return description


func get_icon() -> Texture:
	var tex: Texture = load(icon_path)
	if tex is Texture:
		return tex
	else:
		return FALLBACK_TEXTURE
