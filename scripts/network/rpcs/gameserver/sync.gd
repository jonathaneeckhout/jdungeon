extends Node

class_name SyncRPC

@rpc("call_remote", "authority", "unreliable")
func playersynchronizer_sync_pos(c: int, p: Vector2, v: Vector2):
	if G.client_player == null:
		return

	if G.client_player.component_list.has("player_synchronizer"):
		G.client_player.component_list["player_synchronizer"].sync_pos(c, p, v)


@rpc("call_remote", "any_peer", "reliable")
func playersynchronizer_sync_input(c: int, d: Vector2, t: float, m: Vector2):
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
		user.player.component_list["player_synchronizer"].sync_input(c, d, t, m)


@rpc("call_remote", "any_peer", "reliable") func playersynchronizer_sync_interact(t: String):
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
		user.player.component_list["player_synchronizer"].sync_interact(t)


@rpc("call_remote", "authority", "unreliable")
func positionsynchronizer_sync(n: String, t: float, p: Vector2, v: Vector2):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("position_synchronizer"):
		entity.component_list["position_synchronizer"].sync(t, p, v)


@rpc("call_remote", "any_peer", "reliable") func statssynchronizer_sync_stats(n: String):
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
		entity.component_list["stats_synchronizer"].sync_stats()


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_response(n: String, d: Dictionary):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_response(d)


@rpc("call_remote", "authority", "reliable") func statssynchronizer_sync_int_change(
	n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: int
):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_int_change(t, s, v)


@rpc("call_remote", "authority", "reliable") func statssynchronizer_sync_float_change(
	n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: float
):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_float_change(t, s, v)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_hurt(n: String, t: float, f: String, c: int, d: int):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_hurt(t, f, c, d)


@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_heal(n: String, t: float, f: String, c: int, h: int):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_heal(t, f, c, h)

@rpc("call_remote", "authority", "reliable")
func statssynchronizer_sync_energy_recovery(n: String, t: float, f: String, e: int, r: int):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_energy_recovery(t, f, e, r)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_player(n: String, u: String, p: Vector2):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_player(u, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_player(n: String, u: String):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_player(u)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_enemy(n: String, en: String, ec: String, p: Vector2):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_enemy(en, ec, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_enemy(n: String, en: String):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_enemy(en)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_npc(n: String, nn: String, nc: String, p: Vector2):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_npc(nn, nc, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_npc(n: String, nn: String):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_npc(nn)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_add_item(n: String, iu: String, ic: String, p: Vector2):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_item(iu, ic, p)


@rpc("call_remote", "authority", "reliable")
func networkviewsynchronizer_remove_item(n: String, iu: String):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_item(iu)


@rpc("call_remote", "any_peer", "reliable") func networkviewsynchronizer_sync_bodies_in_view():
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
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("action_synchronizer"):
		entity.component_list["action_synchronizer"].sync_attack(t, d)


@rpc("call_remote", "authority", "reliable")
func actionsynchronizer_sync_skill_use(n: String, t: float, p: Vector2, s: String):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("action_synchronizer"):
		entity.component_list["action_synchronizer"].sync_skill_use(t, p, s)


@rpc("call_remote", "any_peer", "reliable") func skillcomponent_sync_skills(n: String):
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
		entity.component_list["skill_component"].sync_skills()


@rpc("call_remote", "authority", "reliable")
func skillcomponent_sync_response(n: String, d: Dictionary):
	var entity: Node = G.world.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("skill_component"):
		entity.component_list["skill_component"].sync_response(d)


@rpc("call_remote", "any_peer", "reliable")
func playersynchronizer_sync_skill_use(p: Vector2, s: String):
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
		user.player.component_list["player_synchronizer"].sync_skill_use(p, s)
