extends Node

class_name SyncRPC

const MAX_ENTITIES_PER_SYNC: int = 24

## Network metrics
var metrics: Dictionary = {}

var sync_buffer: Dictionary = {}


func _ready():
	if Global.env_network_profiling:
		metrics["playersynchronizer_sync_pos"] = 0
		metrics["playersynchronizer_sync_input"] = 0
		metrics["playersynchronizer_sync_interact"] = 0
		metrics["playersynchronizer_request_attack"] = 0
		metrics["positionsynchronizer_sync"] = 0
		metrics["statssynchronizer_sync_stats"] = 0
		metrics["statssynchronizer_sync_response"] = 0
		metrics["playersynchronizer_request_attack"] = 0
		metrics["statssynchronizer_sync_int_change"] = 0
		metrics["statssynchronizer_sync_float_change"] = 0
		metrics["statssynchronizer_sync_hurt"] = 0
		metrics["statssynchronizer_sync_heal"] = 0
		metrics["statssynchronizer_sync_energy_recovery"] = 0
		metrics["networkviewsynchronizer_add_player"] = 0
		metrics["networkviewsynchronizer_remove_player"] = 0
		metrics["networkviewsynchronizer_add_enemy"] = 0
		metrics["networkviewsynchronizer_remove_enemy"] = 0
		metrics["networkviewsynchronizer_add_npc"] = 0
		metrics["networkviewsynchronizer_remove_npc"] = 0
		metrics["networkviewsynchronizer_add_item"] = 0
		metrics["networkviewsynchronizer_remove_item"] = 0
		metrics["networkviewsynchronizer_sync_bodies_in_view"] = 0
		metrics["actionsynchronizer_sync_attack"] = 0
		metrics["actionsynchronizer_sync_skill_use"] = 0
		metrics["skillcomponent_sync_skills"] = 0
		metrics["skillcomponent_sync_response"] = 0
		metrics["playersynchronizer_sync_skill_use"] = 0
		metrics["characterclasscomponent_sync_all"] = 0
		metrics["characterclasscomponent_sync_response"] = 0
		metrics["characterclasscomponent_sync_class_change"] = 0
		metrics["dialoguesynchronizer_sync_invoke_response"] = 0
		metrics["dialoguesynchronizer_sync_dialogue_finished"] = 0
		metrics["statuseffectcomponent_sync_effect"] = 0
		metrics["statuseffectcomponent_sync_effect_response"] = 0
		metrics["statuseffectcomponent_sync_all"] = 0
		metrics["statuseffectcomponent_sync_all_response"] = 0


func _process(_delta):
	for player in sync_buffer:
		for i in range(0, sync_buffer[player].size(), MAX_ENTITIES_PER_SYNC):
			var batch_size = min(MAX_ENTITIES_PER_SYNC, sync_buffer[player].size() - i)
			var batch = sync_buffer[player].slice(i, i + batch_size)

			# Process the current batch
			positionsynchronizer_sync.rpc_id(player, batch)

	sync_buffer.clear()


@rpc("call_remote", "authority", "unreliable")
func playersynchronizer_sync_pos(c: int, p: Vector2):
	if Global.env_network_profiling:
		metrics["playersynchronizer_sync_pos"] += 1

	if G.client_player == null:
		return

	if G.client_player.component_list.has("player_synchronizer"):
		G.client_player.component_list["player_synchronizer"].client_sync_pos(c, p)


@rpc("call_remote", "any_peer", "reliable")
func playersynchronizer_sync_input(c: int, d: Vector2, t: float):
	if Global.env_network_profiling:
		metrics["playersynchronizer_sync_input"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: G.User = G.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_input(c, d, t)


@rpc("call_remote", "any_peer", "reliable")
func playersynchronizer_sync_interact(t: String):
	if Global.env_network_profiling:
		metrics["playersynchronizer_sync_interact"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: G.User = G.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_interact(t)


@rpc("call_remote", "any_peer", "reliable")
func playersynchronizer_request_attack(t: float, e: Array):
	if Global.env_network_profiling:
		metrics["playersynchronizer_request_attack"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: G.User = G.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_handle_attack_request(t, e)


func positionsynchronizer_queue_sync(
	player: int, entity: String, timestamp: float, position: Vector2
):
	if player in sync_buffer:
		sync_buffer[player].append([entity, timestamp, position])
	else:
		sync_buffer[player] = [[entity, timestamp, position]]


@rpc("call_remote", "authority", "unreliable")
func positionsynchronizer_sync(e: Array):
	if Global.env_network_profiling:
		metrics["positionsynchronizer_sync"] += 1

	for synced_entity in e:
		var entity: Node = G.world.get_entity_by_name(synced_entity[0])

		if entity == null:
			return

		if entity.get("component_list") == null:
			return

		if entity.component_list.has("position_synchronizer"):
			entity.component_list["position_synchronizer"].sync(synced_entity[1], synced_entity[2])


#Called by client, runs on server
@rpc("call_remote", "any_peer", "reliable")
func statssynchronizer_sync_stats(n: String):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_stats"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_stats(id)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_response(n: String, d: Dictionary):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_response"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_response(d)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_int_change(
	n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: int
):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_int_change"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_int_change(t, s, v)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_float_change(
	n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: float
):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_float_change"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_float_change(t, s, v)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_hurt(n: String, t: float, f: String, c: int, d: int):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_hurt"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_hurt(t, f, c, d)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_heal(n: String, t: float, f: String, c: int, h: int):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_heal"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_heal(t, f, c, h)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_energy_recovery(n: String, t: float, f: String, e: int, r: int):
	if Global.env_network_profiling:
		metrics["statssynchronizer_sync_energy_recovery"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_energy_recovery(t, f, e, r)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_player(n: String, u: String, p: Vector2):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_add_player"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_player(u, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_player(n: String, u: String):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_remove_player"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_player(u)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_enemy(n: String, en: String, ec: String, p: Vector2):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_add_enemy"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_enemy(en, ec, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_enemy(n: String, en: String):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_remove_enemy"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_enemy(en)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_npc(n: String, nn: String, nc: String, p: Vector2):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_add_npc"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_npc(nn, nc, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_npc(n: String, nn: String):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_remove_npc"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_npc(nn)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_item(n: String, iu: String, ic: String, p: Vector2):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_add_item"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_item(iu, ic, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_item(n: String, iu: String):
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_remove_item"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_item(iu)


@rpc("call_remote", "any_peer", "reliable")
func networkviewsynchronizer_sync_bodies_in_view():
	if Global.env_network_profiling:
		metrics["networkviewsynchronizer_sync_bodies_in_view"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: G.User = G.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("networkview_synchronizer"):
		user.player.component_list["networkview_synchronizer"].sync_bodies_in_view()


@rpc("call_remote", "authority", "reliable")
func actionsynchronizer_sync_attack(n: String, t: float, d: Vector2):
	if Global.env_network_profiling:
		metrics["actionsynchronizer_sync_attack"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("action_synchronizer"):
		entity.component_list["action_synchronizer"].sync_attack(t, d)


@rpc("call_remote", "authority", "reliable")
func actionsynchronizer_sync_skill_use(n: String, t: float, p: Vector2, s: String):
	if Global.env_network_profiling:
		metrics["actionsynchronizer_sync_skill_use"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("action_synchronizer"):
		entity.component_list["action_synchronizer"].sync_skill_use(t, p, s)


#Server only
@rpc("call_remote", "any_peer", "reliable")
func skillcomponent_sync_skills(n: String):
	if Global.env_network_profiling:
		metrics["skillcomponent_sync_skills"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("skill_component"):
		entity.component_list["skill_component"].sync_skills(id)


#Client only
@rpc("call_remote", "authority", "reliable")
func skillcomponent_sync_response(n: String, d: Dictionary):
	if Global.env_network_profiling:
		metrics["skillcomponent_sync_response"] += 1

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("skill_component"):
		entity.component_list["skill_component"].sync_response(d)


@rpc("call_remote", "any_peer", "reliable")
func playersynchronizer_sync_skill_use(p: Vector2, s: String):
	if Global.env_network_profiling:
		metrics["playersynchronizer_sync_skill_use"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: G.User = G.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_skill_use(p, s)


#Only client can make this RPC, runs on server
@rpc("call_remote", "any_peer", "reliable")
func characterclasscomponent_sync_all(n: String):
	if Global.env_network_profiling:
		metrics["characterclasscomponent_sync_all"] += 1

	if not G.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("class_component"):
		entity.component_list["class_component"].sync_all(id)


#Only server can make this RPC, runs on client
@rpc("call_remote", "authority", "reliable")
func characterclasscomponent_sync_response(n: String, d: Dictionary):
	if Global.env_network_profiling:
		metrics["characterclasscomponent_sync_response"] += 1

	assert(not G.is_server(), "This method is only intended for client use")
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("class_component"):
		entity.component_list["class_component"].sync_response(d)


#Only client can make this RPC, runs on server
@rpc("call_remote", "any_peer", "reliable")
func characterclasscomponent_sync_class_change(n: String, c: Array):
	if Global.env_network_profiling:
		metrics["characterclasscomponent_sync_class_change"] += 1

	if not G.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("class_component"):
		#The component can run it's own checks to verify it is allowed to change them.

		#Temporary adding this typecast to prevent errorcode caused by: https://github.com/godotengine/godot/issues/69215
		var stringArray: Array[String] = []
		stringArray.assign(c)
		entity.component_list["class_component"].replace_classes(stringArray)

		characterclasscomponent_sync_all(n)

		statssynchronizer_sync_stats(n)


#Only server can make this RPC, runs on client
@rpc("call_remote", "authority", "reliable")
func dialoguesynchronizer_sync_invoke_response(n: String, d: String):
	if Global.env_network_profiling:
		metrics["dialoguesynchronizer_sync_invoke_response"] += 1

	assert(not G.is_server(), "This method is only intended for client use")
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("dialogue_component"):
		entity.component_list["dialogue_component"].sync_invoke_response(d)


#Only client can make this RPC, runs on server
@rpc("call_remote", "any_peer", "reliable")
func dialoguesynchronizer_sync_dialogue_finished(n: String):
	if Global.env_network_profiling:
		metrics["dialoguesynchronizer_sync_dialogue_finished"] += 1

	if not G.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("dialogue_component"):
		(
			entity
			. component_list["dialogue_component"]
			. dialogue_system_instance
			. dialogue_finished
			. emit()
		)


@rpc("call_remote", "any_peer", "reliable")
func statuseffectcomponent_sync_effect(n: String, s: String):
	if Global.env_network_profiling:
		metrics["statuseffectcomponent_sync_effect"] += 1

	assert(not G.is_server(), "This method is only intended for client use")
	if not G.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(StatusEffectComponent.COMPONENT_NAME):
		entity.component_list[StatusEffectComponent.COMPONENT_NAME].sync_effect(id, s)


#Only server can make this RPC, runs on client
@rpc("call_remote", "authority", "reliable")
func statuseffectcomponent_sync_effect_response(n: String, s: String, j: Dictionary, r: bool):
	if Global.env_network_profiling:
		metrics["statuseffectcomponent_sync_effect_response"] += 1

	assert(not G.is_server(), "This method is only intended for client use")
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(StatusEffectComponent.COMPONENT_NAME):
		entity.component_list[StatusEffectComponent.COMPONENT_NAME].sync_effect_response(s, j, r)


@rpc("call_remote", "any_peer", "reliable")
func statuseffectcomponent_sync_all(n: String):
	if Global.env_network_profiling:
		metrics["statuseffectcomponent_sync_all"] += 1

	assert(not G.is_server(), "This method is only intended for client use")
	if not G.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(StatusEffectComponent.COMPONENT_NAME):
		entity.component_list[StatusEffectComponent.COMPONENT_NAME].sync_all(id)


#Only server can make this RPC, runs on client
@rpc("call_remote", "authority", "reliable")
func statuseffectcomponent_sync_all_response(n: String, d: Dictionary):
	if Global.env_network_profiling:
		metrics["statuseffectcomponent_sync_all_response"] += 1

	assert(not G.is_server(), "This method is only intended for client use")
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(StatusEffectComponent.COMPONENT_NAME):
		entity.component_list[StatusEffectComponent.COMPONENT_NAME].sync_all_response(d)


#Only server can make this RPC, runs on client
@rpc("call_remote", "authority", "reliable")
func projectilesynchronizer_sync_launch(n: String, d: Dictionary):
	assert(not G.is_server(), "This method is only intended for client use")
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(ProjectileSynchronizerComponent.COMPONENT_NAME):
		(
			entity
			. component_list[ProjectileSynchronizerComponent.COMPONENT_NAME]
			. sync_launch_to_client_response(d)
		)


@rpc("call_remote", "authority", "reliable")
func projectilesynchronizer_sync_collision(n: String, d: Dictionary):
	assert(not G.is_server(), "This method is only intended for client use")
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(ProjectileSynchronizerComponent.COMPONENT_NAME):
		(
			entity
			. component_list[ProjectileSynchronizerComponent.COMPONENT_NAME]
			. sync_collision_to_client_response(d)
		)
