extends StatusEffectResource

## How much damage to deal per proc
@export var damage: int = 1
## Damage is multiplied per stack
@export var scale_per_stack: bool
## Wether to proc during each tick or during timeout.
@export var proc_on_timeout: bool


func _effect_timeout(target: Node, json_data: Dictionary):
	if not proc_on_timeout:
		return

	var targetStats: StatsSynchronizerComponent = G.world.get_entity_component_by_name(
		target.get_name(), StatsSynchronizerComponent.COMPONENT_NAME
	)
	var entity: Node = G.world.get_entity_by_name(json_data["applier"])
	var damageDealt: int = damage
	if scale_per_stack:
		damageDealt = damage * json_data["stacks"]
	targetStats.hurt(entity, damageDealt)


func _effect_tick(target: Node, json_data: Dictionary):
	if proc_on_timeout:
		return

	var targetStats: StatsSynchronizerComponent = G.world.get_entity_component_by_name(
		target.get_name(), StatsSynchronizerComponent.COMPONENT_NAME
	)
	var entity: Node = G.world.get_entity_by_name(json_data["applier"])
	var damageDealt: int = damage
	if scale_per_stack:
		damageDealt = damage * json_data["stacks"]
	targetStats.hurt(entity, damageDealt)
