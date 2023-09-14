extends Node2D

class_name GMFWorld

@export var enemies_to_sync: Array[GMFEnemyBody2D] = []

var players: Node2D
var enemies: Node2D
var npcs: Node2D

var players_by_id = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var entities = Node2D.new()
	entities.name = "GMFEntities"

	players = Node2D.new()
	players.name = "GMFPlayers"
	entities.add_child(players)

	enemies = Node2D.new()
	enemies.name = "GMFEnemies"
	entities.add_child(enemies)

	npcs = Node2D.new()
	npcs.name = "GMFNPCs"
	entities.add_child(npcs)

	add_child(entities)

	if Gmf.is_server():
		Gmf.signals.server.player_logged_in.connect(_on_player_logged_in)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	else:
		Gmf.signals.client.player_added.connect(_on_client_player_added)
		Gmf.signals.client.other_player_added.connect(_on_client_other_player_added)
		Gmf.signals.client.enemy_added.connect(_on_client_enemy_added)
	load_enemies()


func load_enemies():
	for enemy in enemies_to_sync:
		enemy.get_parent().remove_child(enemy)

		if Gmf.is_server():
			enemies.add_child(enemy)


func _on_player_logged_in(id: int, username: String):
	Gmf.logger.info("Adding player=[%s] with id=[%d]" % [username, id])

	var player: GMFPlayerBody2D = Gmf.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = id

	players.add_child(player)
	player.server_synchronizer.start()

	# Add to this list for internal tracking
	players_by_id[id] = player

	Gmf.rpcs.player.add_player.rpc_id(id, id, username, player.position)


func _on_peer_disconnected(id):
	if id in players_by_id:
		var player = players_by_id[id]

		Gmf.logger.info("Removing player=[%s]" % player.name)

		# Disable physics which stops the sync
		player.set_physics_process(false)
		player.queue_free()

		players_by_id.erase(id)


func _on_client_player_added(id: int, username: String, pos: Vector2):
	var player: GMFPlayerBody2D = Gmf.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = id

	player.enable_input = true
	player.position = pos

	players.add_child(player)
	player.server_synchronizer.start()


func _on_client_other_player_added(username: String, pos: Vector2):
	var player = Gmf.player_scene.instantiate()
	player.name = username
	player.username = username
	player.position = pos

	players.add_child(player)
	player.server_synchronizer.start()


func _on_client_enemy_added(enemy_name: String, enemy_class: String, pos: Vector2):
	var enemy = Gmf.enemies_scene[enemy_class].instantiate()
	enemy.name = enemy_name
	enemy.position = pos

	enemies.add_child(enemy)
	enemy.server_synchronizer.start()
