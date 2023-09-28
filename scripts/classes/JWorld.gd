extends Node2D

class_name JWorld

@export var enemies_to_sync: Node2D
@export var npcs_to_sync: Node2D

var players: Node2D
var enemies: Node2D
var npcs: Node2D
var items: Node2D
var enemy_respawns: Node2D

var players_by_id = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var entities = Node2D.new()
	entities.name = "JEntities"
	entities.y_sort_enabled = true
	add_child(entities)

	players = Node2D.new()
	players.name = "JPlayers"
	players.y_sort_enabled = true
	entities.add_child(players)

	enemies = Node2D.new()
	enemies.name = "JEnemies"
	enemies.y_sort_enabled = true
	entities.add_child(enemies)

	npcs = Node2D.new()
	npcs.name = "JNPCs"
	npcs.y_sort_enabled = true
	entities.add_child(npcs)

	items = Node2D.new()
	items.name = "JItems"
	items.y_sort_enabled = true
	entities.add_child(items)

	if J.is_server():
		J.rpcs.account.player_logged_in.connect(_on_player_logged_in)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

		enemy_respawns = Node2D.new()
		enemy_respawns.name = "JEnemyRespawns"
		entities.add_child(enemy_respawns)
	else:
		J.rpcs.player.player_added.connect(_on_client_player_added)

		J.rpcs.player.other_player_added.connect(_on_client_other_player_added)
		J.rpcs.player.other_player_removed.connect(_on_client_other_player_removed)

		J.rpcs.enemy.enemy_added.connect(_on_client_enemy_added)
		J.rpcs.enemy.enemy_removed.connect(_on_client_enemy_removed)

		J.rpcs.npc.npc_added.connect(_on_client_npc_added)
		J.rpcs.npc.npc_removed.connect(_on_client_npc_removed)

		J.rpcs.item.item_added.connect(_on_client_item_added)
		J.rpcs.item.item_removed.connect(_on_client_item_removed)

	J.world = self

	load_enemies()
	load_npcs()


func load_enemies():
	for enemy in enemies_to_sync.get_children():
		enemy.name = str(enemy.get_instance_id())
		enemy.get_parent().remove_child(enemy)

		if J.is_server():
			enemies.add_child(enemy)


func load_npcs():
	for npc in npcs_to_sync.get_children():
		npc.name = str(npc.get_instance_id())
		npc.get_parent().remove_child(npc)

		if J.is_server():
			npcs.add_child(npc)


func queue_enemy_respawn(enemy_class: String, respawn_position: Vector2, respawn_time: float):
	var respawn: JEnemyRespawn = load("res://scripts/classes/JEnemyRespawn.gd").new()
	respawn.enemy_class = enemy_class
	respawn.respawn_position = respawn_position
	respawn.respawn_time = respawn_time

	enemy_respawns.add_child(respawn)


func get_player_by_peer_id(peer_id: int) -> JPlayerBody2D:
	for player in players.get_children():
		if player.peer_id == peer_id:
			return player

	return null


func _on_player_logged_in(id: int, username: String):
	J.logger.info("Adding player=[%s] with id=[%d]" % [username, id])

	var player: JPlayerBody2D = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = id

	players.add_child(player)

	# Add to this list for internal tracking
	players_by_id[id] = player

	J.rpcs.player.add_player.rpc_id(id, id, username, player.position)


func _on_peer_disconnected(id):
	if id in players_by_id:
		var player = players_by_id[id]

		J.logger.info("Removing player=[%s]" % player.name)

		# Disable physics which stops the sync
		player.set_physics_process(false)
		player.queue_free()

		players_by_id.erase(id)


func _on_client_player_added(id: int, username: String, pos: Vector2):
	var player: JPlayerBody2D = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.peer_id = id

	player.position = pos

	players.add_child(player)

	J.client.player = player


func _on_client_other_player_added(username: String, pos: Vector2):
	var player = J.player_scene.instantiate()
	player.name = username
	player.username = username
	player.position = pos

	players.add_child(player)


func _on_client_other_player_removed(username: String):
	if players.has_node(username):
		players.get_node(username).queue_free()


func _on_client_enemy_added(enemy_name: String, enemy_class: String, pos: Vector2):
	var enemy: JEnemyBody2D = J.enemy_scenes[enemy_class].instantiate()
	enemy.name = enemy_name
	enemy.position = pos

	enemies.add_child(enemy)


func _on_client_enemy_removed(enemy_name: String):
	if enemies.has_node(enemy_name):
		enemies.get_node(enemy_name).queue_free()


func _on_client_npc_added(npc_name: String, npc_class: String, pos: Vector2):
	var npc: JNPCBody2D = J.npc_scenes[npc_class].instantiate()
	npc.name = npc_name
	npc.position = pos

	npcs.add_child(npc)


func _on_client_npc_removed(npc_name: String):
	if npcs.has_node(npc_name):
		npcs.get_node(npc_name).queue_free()


func _on_client_item_added(item_uuid: String, item_class: String, pos: Vector2):
	var item: JItem = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.position = pos
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	items.add_child(item)


func _on_client_item_removed(item_uuid: String):
	if items.has_node(item_uuid):
		items.get_node(item_uuid).queue_free()
