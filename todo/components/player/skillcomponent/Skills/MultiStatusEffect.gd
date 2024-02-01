extends SkillComponentResource

@export var statuses_to_apply: Array[String]
@export var duration: float
@export var stacks: int


func _effect(information: SkillUseInfo):
	for target: Node in information.targets:
		var statusComp: StatusEffectComponent = G.world.get_entity_component_by_name(
			target.get_name(), StatusEffectComponent.COMPONENT_NAME
		)

		if not statusComp is StatusEffectComponent:
			if Global.debug_mode:
				(
					GodotLogger
					. warn(
						(
							"Failed to apply status effect to {0} due to a lack of a StatusEffectComponent"
							. format([target.get_name()])
						)
					)
				)
			return

		for status: String in statuses_to_apply:
			statusComp.add_status_effect(status, target, stacks, duration)
