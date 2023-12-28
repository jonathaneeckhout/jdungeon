extends SkillComponentResource

@export var add_attack_stat: bool

@export var damage_bonus: int
@export var damage_modifier: float = 1


func _effect(information: SkillUseInfo):
	var statComp: StatsSynchronizerComponent = G.world.get_entity_component_by_name(
		information.get_user_name(), StatsSynchronizerComponent.COMPONENT_NAME
	)
	var damageDealt: int
	if add_attack_stat:
		damageDealt = (statComp.get_attack_damage() + damage_bonus) * damage_modifier
	else:
		damageDealt = damage_bonus * damage_modifier

	for stats: StatsSynchronizerComponent in information.get_target_stats_all():
		# Leave the dead alone
		if stats.is_dead:
			continue

		stats.hurt(information.user, damageDealt)
