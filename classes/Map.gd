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

# @export var respawn_locations: Node3D = null

# ## Node grouping all the players
# var players: Node3D = null

# ## Node grouping all the projectiles
# var projectiles: Node3D = null

# var client_decorations: Node = null

# var _player_spawn_synchronizer: PlayerSpawnerSynchronizer = null

# func _ready():
# 	multiplayer_connection.map = self

# 	randomize()

# 	# Create the players node
# 	players = Node3D.new()
# 	players.name = "Players"
# 	add_child(players)

# 	# Create the projectiles node
# 	projectiles = Node3D.new()
# 	projectiles.name = "Projectiles"
# 	add_child(projectiles)

# 	# Create the projectiles node
# 	client_decorations = Node3D.new()
# 	client_decorations.name = "ClientDecorations"
# 	add_child(client_decorations)

# func map_init() -> bool:
# 	# Common code
# 	_player_spawn_synchronizer = (multiplayer_connection.component_list.get_component(
# 		PlayerSpawnerSynchronizer.COMPONENT_NAME
# 	))

# 	assert(_player_spawn_synchronizer != null, "Failed to get PlayerSpawnerSynchronizer component")

# 	# Server-side logic
# 	if multiplayer_connection.is_server():
# 		_player_spawn_synchronizer.server_player_added.connect(_on_server_player_added)
# 		_player_spawn_synchronizer.server_player_removed.connect(_on_server_player_removed)

# 	# Client-side logic
# 	else:
# 		# Listen to the signal for your player to be added
# 		_player_spawn_synchronizer.client_player_added.connect(_on_client_player_added)
# 		_player_spawn_synchronizer.client_player_removed.connect(_on_client_player_removed)
# 	return true

# func get_random_spawn_location():
# 	# Get how many respawn locations there are in this map
# 	var number_of_respawn_location: int = respawn_locations.get_child_count()

# 	# Pick a random index of the childs
# 	var random_spawn_location_index: int = randi() % number_of_respawn_location

# 	# Get that random child
# 	var random_spawn_location: RespawnLocation = respawn_locations.get_child(
# 		random_spawn_location_index
# 	)

# 	# Return the position of this random respawn location
# 	return random_spawn_location.position

# ## Return an player by it's name if it doesn't exist it will return null
# func get_player_by_name(player_name: String) -> Player:
# 	return players.get_node_or_null(player_name)

# func _on_server_player_added(username: String, peer_id: int):
# 	# Fetch the user from the connection list
# 	var user: MultiplayerConnection.User = multiplayer_connection.get_user_by_id(peer_id)
# 	if user == null:
# 		GodotLogger.warn("Could not find user with id=%d" % peer_id)
# 		return

# 	var new_player: Player = player_scene.instantiate()
# 	new_player.name = username
# 	new_player.peer_id = peer_id
# 	new_player.position = get_random_spawn_location()
# 	new_player.multiplayer_connection = multiplayer_connection

# 	GodotLogger.info("Adding player=[%s] with id=[%d] to the map" % [new_player.name, peer_id])

# 	# Add the player to the world
# 	players.add_child(new_player)

# 	user.player = new_player

# 	_player_spawn_synchronizer.add_client_player(
# 		new_player.peer_id, new_player.name, new_player.position, true
# 	)

# func _on_server_player_removed(username: String):
# 	# Try to get the player with the given username
# 	var player: Player = players.get_node_or_null(username)
# 	if player == null:
# 		return

# 	GodotLogger.info("Removing player=[%s] from the map" % username)

# 	_player_spawn_synchronizer.remove_client_player(player.peer_id, player.name)

# 	# Make sure this player isn't updated anymore
# 	player.set_physics_process(false)

# 	# Queue the player for deletions
# 	player.queue_free()

# func _on_client_player_added(username: String, pos: Vector3, own_player: bool):
# 	if players.has_node(username):
# 		GodotLogger.info("Player=[%s] already exists, no need to add again" % username)
# 		return

# 	GodotLogger.info("Adding player=[%s] to the map" % username)

# 	var new_player: Player = player_scene.instantiate()
# 	new_player.name = username
# 	new_player.position = pos
# 	new_player.multiplayer_connection = multiplayer_connection

# 	if own_player:
# 		multiplayer_connection.client_player = new_player

# 	# Add the player to the world
# 	players.add_child(new_player)

# func _on_client_player_removed(username: String):
# 	# Try to get the player with the given username
# 	var player: Player = players.get_node_or_null(username)
# 	if player == null:
# 		return

# 	GodotLogger.info("Removing player=[%s] from the map" % username)

# 	# Make sure this player isn't updated anymore
# 	player.set_physics_process(false)

# 	# Queue the player for deletions
# 	player.queue_free()
