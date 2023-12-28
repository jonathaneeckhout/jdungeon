extends Node2D

class_name World

@export var map_to_sync: Node2D
@export var enemies_to_sync: Node2D
@export var npcs_to_sync: Node2D
@export var player_respawn_locations: Node2D
@export var portals_to_sync: Node2D

var players: Node2D
var enemies: Node2D
var npcs: Node2D
var items: Node2D
var enemy_respawns: Node2D

var players_by_id = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var synced_entities = Node2D.new()
	synced_entities.name = "SyncedEntities"
	synced_entities.y_sort_enabled = true
	add_child(synced_entities)

	players = Node2D.new()
	players.name = "Players"
	players.y_sort_enabled = true
	synced_entities.add_child(players)

	enemies = Node2D.new()
	enemies.name = "Enemies"
	enemies.y_sort_enabled = true
	synced_entities.add_child(enemies)

	npcs = Node2D.new()
	npcs.name = "NPCs"
	npcs.y_sort_enabled = true
	synced_entities.add_child(npcs)

	items = Node2D.new()
	items.name = "Items"
	items.y_sort_enabled = true
	synced_entities.add_child(items)

	if G.is_server():
		G.player_rpc.player_logged_in.connect(_on_player_logged_in)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

		S.server_rpc.user_portalled.connect(_on_user_portalled)

		enemy_respawns = Node2D.new()
		enemy_respawns.name = "EnemyRespawns"
		synced_entities.add_child(enemy_respawns)

	else:
		G.player_rpc.player_added.connect(_on_client_player_added)
		G.player_rpc.get_player.rpc_id(1)

	G.world = self

	# Remove map from entities to make sure it takes part of the ysort mechanics
	map_to_sync.get_parent().remove_child(map_to_sync)
	synced_entities.add_child(map_to_sync)
	map_to_sync.name = "Map"

	portals_to_sync.get_parent().remove_child(portals_to_sync)
	synced_entities.add_child(portals_to_sync)
	portals_to_sync.name = "Portals"

	load_enemies()
	load_npcs()


func load_enemies():
	for enemy in enemies_to_sync.get_children():
		enemy.name = str(enemy.get_instance_id())
		enemy.get_parent().remove_child(enemy)

		if G.is_server():
			enemies.add_child(enemy)


func load_npcs():
	for npc in npcs_to_sync.get_children():
		npc.name = str(npc.get_instance_id())
		npc.get_parent().remove_child(npc)

		if G.is_server():
			npcs.add_child(npc)


func get_portal_information() -> Dictionary:
	var portals_info = {}
	for portal in portals_to_sync.get_children():
		portals_info[portal.name] = {
			"position": portal.get_portal_location(),
			"destination_server": portal.destination_server,
			"destination_portal": portal.destination_portal
		}
	return portals_info


func queue_enemy_respawn(enemy_class: String, respawn_position: Vector2, respawn_time: float):
	var respawn: EnemyRespawn = EnemyRespawn.new()
	respawn.enemy_class = enemy_class
	respawn.respawn_position = respawn_position
	respawn.respawn_time = respawn_time

	enemy_respawns.add_child(respawn)


func get_player_by_peer_id(peer_id: int) -> Player:
	for player in players.get_children():
		if player.peer_id == peer_id:
			return player

	return null


func get_player_by_username(username: String) -> Player:
	return players.get_node_or_null(username)


## Return an entity by it's name if it doesn't exist it will return null
func get_entity_by_name(entity_name: String) -> Node:
	var entity: Node = enemies.get_node_or_null(entity_name)
	if entity != null:
		return entity

	entity = npcs.get_node_or_null(entity_name)
	if entity != null:
		return entity

	entity = players.get_node_or_null(entity_name)
	if entity != null:
		return entity

	entity = items.get_node_or_null(entity_name)
	return entity


## A shortcut to fetch the component of an entity from it's [member component_list] property.
func get_entity_component_by_name(entity_name: String, component_name: String) -> Node:
	var entity: Node = get_entity_by_name(entity_name)
	if entity.get("component_list") is Dictionary:
		var comp: Node = entity.component_list.get(component_name, null)
		if comp == null:
			GodotLogger.error(
				"The user '{0}' lacks a '{1}' component".format([entity.get_name(), component_name])
			)
		return comp
	else:
		GodotLogger.error(
			(
				"The user '{0}' does not have a component_list property, it may not be an entity."
				. format([entity.get_name()])
			)
		)
		return null


func find_player_respawn_location(player_position: Vector2) -> Vector2:
	var spots = player_respawn_locations.get_children()

	if len(spots) == 0:
		GodotLogger.warn("No player respawn spots found, returning current player's position")
		return player_position

	var closest = spots[0].position
	var closest_distance = closest.distance_to(player_position)

	for spot in spots:
		var distance = spot.position.distance_to(player_position)
		if distance < closest_distance:
			closest = spot.position
			closest_distance = distance

	return closest


func _on_player_logged_in(id: int, _username: String):
	var user: G.User = G.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		return

	GodotLogger.info("Adding player=[%s] with id=[%d]" % [user.username, id])

	var player: Player = J.player_scene.instantiate()
	player.name = user.username
	player.username = user.username
	player.server = name
	player.peer_id = id

	players.add_child(player)

	# Reference the player to the user
	user.player = player

	# Add to this list for internal tracking
	players_by_id[id] = player


func _on_peer_disconnected(id):
	if id in players_by_id:
		var player: Player = players_by_id[id]

		# If the player is dead, we will respawn him first before storing the player's data
		if player.stats.is_dead:
			player.position = find_player_respawn_location(player.position)
			player.stats.reset_hp()
			player.stats.reset_energy()

		GodotLogger.info("Removing player=[%s]" % player.name)

		# Disable physics which stops the sync
		player.set_physics_process(false)
		player.queue_free()

		players_by_id.erase(id)


func _on_client_player_added(id: int, username: String, pos: Vector2):
	var player: Player = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = id

	player.position = pos

	G.client_player = player

	players.add_child(player)

	player.network_view_synchronizer.player_added.connect(_on_client_other_player_added)
	player.network_view_synchronizer.player_removed.connect(_on_client_other_player_removed)

	player.network_view_synchronizer.enemy_added.connect(_on_client_enemy_added)
	player.network_view_synchronizer.enemy_removed.connect(_on_client_enemy_removed)

	player.network_view_synchronizer.npc_added.connect(_on_client_npc_added)
	player.network_view_synchronizer.npc_removed.connect(_on_client_npc_removed)

	player.network_view_synchronizer.item_added.connect(_on_client_item_added)
	player.network_view_synchronizer.item_removed.connect(_on_client_item_removed)


func _on_client_other_player_added(username: String, pos: Vector2):
	if players.has_node(username):
		GodotLogger.info("Player=[%s] already exists, no need to add again" % username)
		return

	var player: Player = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.position = pos

	players.add_child(player)


func _on_client_other_player_removed(username: String):
	if players.has_node(username):
		players.get_node(username).queue_free()


func _on_client_enemy_added(enemy_name: String, enemy_class: String, pos: Vector2):
	if enemies.has_node(enemy_name):
		GodotLogger.info("Enemy=[%s] already exists, no need to add again" % enemy_name)
		return

	var enemy: CharacterBody2D = J.enemy_scenes[enemy_class].instantiate()
	enemy.name = enemy_name
	enemy.position = pos
	enemies.add_child(enemy)


func _on_client_enemy_removed(enemy_name: String):
	if enemies.has_node(enemy_name):
		enemies.get_node(enemy_name).queue_free()


func _on_client_npc_added(
	npc_name: String,
	npc_class: String,
	pos: Vector2,
):
	if npcs.has_node(npc_name):
		GodotLogger.info("NPC=[%s] already exists, no need to add again" % npc_name)
		return

	var npc: CharacterBody2D = J.npc_scenes[npc_class].instantiate()
	npc.name = npc_name
	npc.position = pos

	npcs.add_child(npc)


func _on_client_npc_removed(npc_name: String):
	if npcs.has_node(npc_name):
		npcs.get_node(npc_name).queue_free()


func _on_client_item_added(item_uuid: String, item_class: String, pos: Vector2):
	if items.has_node(item_uuid):
		GodotLogger.info("Item=[%s] already exists, no need to add again")
		return

	var item: Item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.position = pos
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	items.add_child(item)


func _on_client_item_removed(item_uuid: String):
	if items.has_node(item_uuid):
		items.get_node(item_uuid).queue_free()


func _on_user_portalled(
	response: bool,
	username: String,
	server_name: String,
	portal_position: Vector2,
	address: String,
	port: int,
	cookie: String
):
	if not response:
		GodotLogger.info("User=[%s] failed to portal" % username)
		return

	GodotLogger.info("User=[%s] portalled" % username)

	var player: Player = get_player_by_username(username)
	if player == null:
		GodotLogger.warn("Could not find player with username=[%s]" % username)
		return

	# Disable the physics of the player
	player.set_physics_process(false)

	# Set the player's values to the new server and portal's location.
	# Once disconnected the persistent storage will store this value.
	player.server = server_name
	player.position = portal_position

	G.player_rpc.portal_player.rpc_id(player.peer_id, server_name, address, port, cookie)

	# Give the player some time to disconnect
	await get_tree().create_timer(1).timeout

	# If the client didn't disconnect by now, force it
	if is_instance_valid(player) and G.users.has(player.peer_id):
		GodotLogger.info("Disconnecting portalled player=[%s]" % player.username)
		G.server.disconnect_peer(player.peer_id)
