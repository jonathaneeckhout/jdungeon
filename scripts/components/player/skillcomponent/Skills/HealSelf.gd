extends SkillComponentResource

@export var healing_amount: int = 20

var audio_settings := SoundManager.new_settings()

func _effect(info: SkillUseInfo):
	var playerStats: StatsSynchronizerComponent = G.world.get_entity_component_by_name(info.get_user_name(), StatsSynchronizerComponent.COMPONENT_NAME)
	var playerNode: Node2D = G.world.get_entity_by_name(info.get_user_name())
	assert(playerNode.get("peer_id") != null)
	
	audio_settings.set_position_2d(playerNode.global_position)
	SoundManager.main_instance.sync_play_on_client(playerNode.peer_id, "HealSpell", SoundManager.CHANNEL_TYPE.POSITIONAL_2D, audio_settings.to_json())
	
	playerStats.heal(info.user.get_name(), healing_amount)

func get_description() -> String:
	return "Heals the user for {0} health.".format([healing_amount])
