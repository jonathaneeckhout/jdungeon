extends StatusEffectResource
## This script is used for status effects that cause stat changes.
## To use this, create a new StatusEffectResource and assign this as it's script.

@export var stat_name_to_boost: String

@export var status_effect_modifier: float = 1.0
@export var status_effect_bonus: int = 0

@export var bonus_scales_with_stacks: bool
@export var modifier_scales_with_stacks: bool

var boost_ref: Boost


func _effect_applied(_target: Node, _json_data: Dictionary):
	assert(
		(
			stat_name_to_boost
			in (
				StatsSynchronizerComponent.StatListPermanent
				+ StatsSynchronizerComponent.StatListCounter
			)
		)
	)
	var targetStatsComp: StatsSynchronizerComponent = G.world.get_entity_component_by_name(
		_target.get_name(), StatsSynchronizerComponent.COMPONENT_NAME
	)

	boost_ref = generate_boost(
		stat_name_to_boost, targetStatsComp.get(stat_name_to_boost), _json_data["stacks"]
	)

	targetStatsComp.apply_boost(boost_ref)


func _effect_stack_change(_target: Node, _json_data: Dictionary):
	var targetStatsComp: StatsSynchronizerComponent = G.world.get_entity_component_by_name(
		_target.get_name(), StatsSynchronizerComponent.COMPONENT_NAME
	)
	targetStatsComp.remove_boost(boost_ref)
	boost_ref = generate_boost(
		stat_name_to_boost, targetStatsComp.get(stat_name_to_boost), _json_data["stacks"]
	)
	targetStatsComp.apply_boost(boost_ref)


func _effect_removed(_target: Node, _json_data: Dictionary):
	var targetStatsComp: StatsSynchronizerComponent = G.world.get_entity_component_by_name(
		_target.get_name(), StatsSynchronizerComponent.COMPONENT_NAME
	)
	targetStatsComp.remove_boost(boost_ref)


func generate_boost(stat_to_boost: String, base_stat_value: int, stacks: int) -> Boost:
	#Example of a 1.5 modifier, with a stat at 100 and a bonus of 5:
	#postModifierResult is set to (100 + 5) * 1.5 = 157 after rounding down.
	#postModifierResult gets -105, leaving it at 52, which equals 50% of 105 (rounded down)
	var newBoost := Boost.new()
	var flatIncrease: int = status_effect_bonus
	if bonus_scales_with_stacks:
		flatIncrease = status_effect_bonus * stacks

	var modifierIncrease: float = status_effect_modifier
	if modifier_scales_with_stacks:
		modifierIncrease = status_effect_modifier * stacks

	var boostValue: int = (
		(base_stat_value + flatIncrease) + ((base_stat_value * modifierIncrease) - base_stat_value)
	)
	newBoost.set_stat_boost(stat_to_boost, boostValue)

	return newBoost


func get_description() -> String:
	var change: String = "Raises" if status_effect_modifier * status_effect_bonus > 0 else "Lowers"
	return (
		'''{change} {stat} by 1 per stack.
	'''
		. format({"change": change, "stat": stat_name_to_boost})
	)
