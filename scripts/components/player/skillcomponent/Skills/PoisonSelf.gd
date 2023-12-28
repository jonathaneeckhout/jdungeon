extends SkillComponentResource
## All arrays must have the same amount of stacks, use -1 to use the default values.


func _effect(information: SkillUseInfo):
	var statusComp: StatusEffectComponent = G.world.get_entity_component_by_name(
		information.get_user_name(), StatusEffectComponent.COMPONENT_NAME
	)
	if not statusComp is StatusEffectComponent:
		return

	statusComp.add_status_effect("Poison", information.user, 100, 1.5)
