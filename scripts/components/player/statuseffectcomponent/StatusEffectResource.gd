extends Resource
class_name StatusEffectResource
## Uses a factor pattern for quick customization.

enum Properties {
	SUM_STACKS
}

@export var class_identifier: String
@export var displayed_name: String = "Unnamed Status"

var owner: Node
var entity_applied: Node
var stacks: int
var duration_left: float

func effect():
	pass

func set_owner(own: Node) -> StatusEffectResource:
	owner = own
	return self

func set_entity_applied(entity: Node) -> StatusEffectResource:
	entity_applied = entity
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
	
