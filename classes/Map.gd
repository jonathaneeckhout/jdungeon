extends Node

class_name Map

@export var multiplayer_connection: MultiplayerConnection = null

## The scene used for this map
@export var player_scene: Resource = null

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
