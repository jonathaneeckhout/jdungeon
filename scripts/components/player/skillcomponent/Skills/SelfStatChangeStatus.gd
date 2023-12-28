extends SkillComponentResource

@export var status_effect: String
@export var stacks: int
@export var duration: float


func _effect(information: SkillUseInfo):
	var statusComp: StatusEffectComponent = G.world.get_entity_component_by_name(
		information.get_user_name(), StatusEffectComponent.COMPONENT_NAME
	)
	statusComp.add_status_effect(
		status_effect, G.world.get_entity_by_name(information.get_user_name()), stacks, duration
	)
