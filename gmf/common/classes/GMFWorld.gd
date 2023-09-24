extends Node2D

class_name GMFWorld

@export var enemies_to_sync: Node2D

var players: Node2D
var enemies: Node2D
var npcs: Node2D
var items: Node2D
var enemy_respawns: Node2D

var players_by_id = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var entities = Node2D.new()
	entities.name = "GMFEntities"
	entities.y_sort_enabled = true
	add_child(entities)

	players = Node2D.new()
	players.name = "GMFPlayers"
	players.y_sort_enabled = true
	entities.add_child(players)

	enemies = Node2D.new()
	enemies.name = "GMFEnemies"
	enemies.y_sort_enabled = true
	entities.add_child(enemies)

	npcs = Node2D.new()
	npcs.name = "GMFNPCs"
	npcs.y_sort_enabled = true
	entities.add_child(npcs)

	items = Node2D.new()
	items.name = "GMFItems"
	items.y_sort_enabled = true
	entities.add_child(items)

	if Gmf.is_server():
		Gmf.signals.server.player_logged_in.connect(_on_player_logged_in)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

		enemy_respawns = Node2D.new()
		enemy_respawns.name = "GMFEnemyRespawns"
		entities.add_child(enemy_respawns)
	else:
		Gmf.signals.client.player_added.connect(_on_client_player_added)

		Gmf.signals.client.other_player_added.connect(_on_client_other_player_added)
		Gmf.signals.client.other_player_removed.connect(_on_client_other_player_removed)

		Gmf.signals.client.enemy_added.connect(_on_client_enemy_added)
		Gmf.signals.client.enemy_removed.connect(_on_client_enemy_removed)

	Gmf.world = self

	load_enemies()


func load_enemies():
	for enemy in enemies_to_sync.get_children():
		enemy.name = str(enemy.get_instance_id())
		enemy.get_parent().remove_child(enemy)

		if Gmf.is_server():
			enemies.add_child(enemy)


func queue_enemy_respawn(enemy_class: String, respawn_position: Vector2, respawn_time: float):
	var respawn: GMFEnemyRespawn = load("res://gmf/common/classes/GMFEnemyRespawn.gd").new()
	respawn.enemy_class = enemy_class
	respawn.respawn_position = respawn_position
	respawn.respawn_time = respawn_time

	enemy_respawns.add_child(respawn)


func _on_player_logged_in(id: int, username: String):
	Gmf.logger.info("Adding player=[%s] with id=[%d]" % [username, id])

	var player: GMFPlayerBody2D = Gmf.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = id

	players.add_child(player)

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

	player.position = pos

	players.add_child(player)

	Gmf.client.player = player


func _on_client_other_player_added(username: String, pos: Vector2):
	var player = Gmf.player_scene.instantiate()
	player.name = username
	player.username = username
	player.position = pos

	players.add_child(player)


func _on_client_other_player_removed(username: String):
	if players.has_node(username):
		players.get_node(username).queue_free()


func _on_client_enemy_added(enemy_name: String, enemy_class: String, pos: Vector2):
	var enemy = Gmf.enemies_scene[enemy_class].instantiate()
	enemy.name = enemy_name
	enemy.position = pos

	enemies.add_child(enemy)


func _on_client_enemy_removed(enemy_name: String):
	if enemies.has_node(enemy_name):
		enemies.get_node(enemy_name).queue_free()
