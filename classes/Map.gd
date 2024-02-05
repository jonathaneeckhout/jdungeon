extends Node

class_name Map

@export var multiplayer_connection: MultiplayerConnection = null

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


# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer_connection.map = self

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

	# Remove map from entities to make sure it takes part of the ysort mechanics
	map_to_sync.get_parent().remove_child(map_to_sync)
	synced_entities.add_child(map_to_sync)
	map_to_sync.name = "Map"

	portals_to_sync.get_parent().remove_child(portals_to_sync)
	synced_entities.add_child(portals_to_sync)
	portals_to_sync.name = "Portals"

	if multiplayer_connection.is_server():
		enemy_respawns = Node2D.new()
		enemy_respawns.name = "EnemyRespawns"
		synced_entities.add_child(enemy_respawns)

	_load_enemies()
	_load_npcs()


func _load_enemies():
	for enemy in enemies_to_sync.get_children():
		enemy.get_parent().remove_child(enemy)

		if multiplayer_connection.is_server():
			enemy.name = str(enemy.get_instance_id())
			enemies.add_child(enemy)

	enemies_to_sync.queue_free()


func _load_npcs():
	for npc in npcs_to_sync.get_children():
		npc.get_parent().remove_child(npc)

		if multiplayer_connection.is_server():
			npc.name = str(npc.get_instance_id())
			npcs.add_child(npc)

	npcs_to_sync.queue_free()


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


func queue_enemy_respawn(enemy_class: String, respawn_position: Vector2, respawn_time: float):
	var respawn: EnemyRespawn = EnemyRespawn.new()
	respawn.enemy_class = enemy_class
	respawn.respawn_position = respawn_position
	respawn.respawn_time = respawn_time
	respawn.map = self

	enemy_respawns.add_child(respawn)


func server_add_player(peer_id: int, username: String, pos: Vector2) -> Player:
	var player: Player = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = peer_id
	player.position = pos

	players.add_child(player)

	return player


func server_remove_player(username: String):
	if players.has_node(username):
		var player: Player = players.get_node(username)
		player.set_physics_process(false)
		player.queue_free()


func client_add_player(peer_id: int, username: String, pos: Vector2, own_player: bool) -> Player:
	if players.has_node(username):
		GodotLogger.info("Player=[%s] already exists, no need to add again" % username)
		return

	var player: Player = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = peer_id
	player.position = pos

	if own_player:
		multiplayer_connection.client_player = player

	players.add_child(player)

	return player


func client_remove_player(username: String):
	if players.has_node(username):
		players.get_node(username).queue_free()


func client_add_enemy(enemy_name: String, enemy_class: String, pos: Vector2):
	if enemies.has_node(enemy_name):
		GodotLogger.info("Enemy=[%s] already exists, no need to add again" % enemy_name)
		return

	var enemy: CharacterBody2D = J.enemy_scenes[enemy_class].instantiate()
	enemy.name = enemy_name
	enemy.position = pos
	enemies.add_child(enemy)


func client_remove_enemy(enemy_name: String):
	if enemies.has_node(enemy_name):
		enemies.get_node(enemy_name).queue_free()


func client_add_npc(
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


func client_remove_npc(npc_name: String):
	if npcs.has_node(npc_name):
		npcs.get_node(npc_name).queue_free()


func client_add_item(item_uuid: String, item_class: String, pos: Vector2):
	if items.has_node(item_uuid):
		GodotLogger.info("Item=[%s] already exists, no need to add again")
		return

	var item: Item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.position = pos
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	items.add_child(item)


func client_remove_item(item_uuid: String):
	if items.has_node(item_uuid):
		items.get_node(item_uuid).queue_free()


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
