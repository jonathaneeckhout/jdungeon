extends SkillComponentResource

@export var projectile_class: String


func effect(information: SkillUseInfo):
	var user_projectile_synchronizer: ProjectileSynchronizerComponent = (
		G
		. world
		. get_entity_component_by_name(
			information.get_user_name(), ProjectileSynchronizerComponent.COMPONENT_NAME
		)
	)

	if not user_projectile_synchronizer is ProjectileSynchronizerComponent:
		return

	user_projectile_synchronizer.launch_projectile(
		information.position_target_global, projectile_class
	)
