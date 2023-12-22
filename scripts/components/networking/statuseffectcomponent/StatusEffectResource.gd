extends Resource
class_name StatusEffectResource
## Uses a factor pattern for quick customization.
## Example:
##	var newStatus := StatusEffectResource.new().set_owner(self).set_duration_left(3.5)

signal target_chosen(node: Node)

const FALLBACK_TEXTURE: Texture = preload("res://icon.svg")

enum Properties {
	STACKS_MULTIPLY_DURATION ## When setting stacks, these act as a multiplier
}

@export var status_class: String
@export var displayed_name: String = "Unnamed Status"
@export_multiline var description: String
@export_file var icon_path: String

@export_group("Combine Behaviour", "behaviour")
## The duration duration of this and the combined status will be added togheter.
## Otherwise the highest duration_left of the two will be chosen.
@export var behaviour_stackable_duration: bool 
## Stacks will not be added togheter,but instead the highest amount of the two statuses will be chosen.
@export var behaviour_stack_override: bool

@export_group("Properties")
@export var stacks: int = 1
@export var duration_left: float = 1.0

## Who originally created this status effect
var owner: Node
## Who it is meant to affect
var target: Node

func effect():
	_effect()

func _effect():
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

func get_entity_stats_component(node: Node) -> StatsSynchronizerComponent:
	var stats: StatsSynchronizerComponent = node.get("stats")
	
	if not stats: 
		GodotLogger.error("The node given is not an entity.")
		
	return stats

func set_owner(own: Node) -> StatusEffectResource:
	owner = own
	return self

func set_target(targ: Node) -> StatusEffectResource:
	target = targ
	return self

func set_duration_left(duration: float) -> StatusEffectResource:
	duration_left = duration
	return self

func change_duration_left(duration: float) -> StatusEffectResource:
	duration_left += duration
	return self

func set_stacks(sta: int) -> StatusEffectResource:
	stacks = sta
	return self
	
func change_stacks(sta: int) -> StatusEffectResource:
	stacks += sta
	return self
	
## Attempts to combine a status effect with this one.
func combine_status(status_effect: StatusEffectResource):
	set_target(status_effect.target)
	
	# If it can be stacked, add both togheter, otherwise, set duration to to highest of the two
	if behaviour_stackable_duration:
		change_duration_left(status_effect.duration_left)
	else:
		set_duration_left( max(duration_left, status_effect.duration_left) )
	
	if behaviour_stack_override:
		set_stacks( max(stacks, status_effect.stacks) )
	else:
		change_stacks( status_effect.stacks )

func to_json() -> Dictionary:
	return {
			"class": status_class, 
			"owner": owner.get_name(),
			"target": target.get_name(),
			"duration_left": duration_left,
			"stacks": stacks
		}

func from_json(data: Dictionary):
	if data.size() != 5:
		GodotLogger.error("Data size mismatch.")
	# "class" is ignored and only used by the component.
	owner = G.world.get_entity_by_name(data["owner"])
	target = G.world.get_entity_by_name(data["target"])
	duration_left = data["duration_left"]
	stacks = data["stacks"]
