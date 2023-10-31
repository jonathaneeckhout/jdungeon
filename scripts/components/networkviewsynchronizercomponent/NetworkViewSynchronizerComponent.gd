extends Node2D

class_name NetworkViewSynchronizerComponent

signal body_entered(body: Node2D)
signal body_exited(body: Node2D)

signal player_added(username: String, pos: Vector2)
signal player_removed(username: String)

signal enemy_added(enemy_name: String, enemy_class: String, pos: Vector2)
signal enemy_removed(enemy_name: String)

signal npc_added(npc_name: String, npc_class: String, pos: Vector2)
signal npc_removed(npc_name: String)

signal item_added(item_uuid: String, item_class: String, pos: Vector2)
signal item_removed(item_uuid: String)

@export var network_sync_area_size: float = 2048.0

var target_node: Node
var bodies_in_view: Array[Node2D] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	target_node = get_parent()

	if target_node.get("peer_id") == null:
		J.logger.error("target_node does not have the peer_id variable")
		return

	if J.is_server():
		var cs_network_view_circle = CircleShape2D.new()
		cs_network_view_circle.radius = network_sync_area_size

		var cs_body_network_view_area = CollisionShape2D.new()
		cs_body_network_view_area.name = "BodyNetworkViewAreaCollisionShape2D"
		cs_body_network_view_area.shape = cs_network_view_circle

		var body_network_view_area = Area2D.new()
		body_network_view_area.name = "BodyNetworkViewArea"
		body_network_view_area.collision_layer = J.PHYSICS_LAYER_NETWORKING
		body_network_view_area.collision_mask = (
			J.PHYSICS_LAYER_PLAYERS
			+ J.PHYSICS_LAYER_ENEMIES
			+ J.PHYSICS_LAYER_NPCS
			+ J.PHYSICS_LAYER_ITEMS
		)
		body_network_view_area.add_child(cs_body_network_view_area)

		add_child(body_network_view_area)

		body_network_view_area.body_entered.connect(_on_body_network_view_area_body_entered)
		body_network_view_area.body_exited.connect(_on_body_network_view_area_body_exited)


func _on_body_network_view_area_body_entered(body: Node2D):
	# Don't handle the player as we hardcoded it to be added to the watchers
	if body == target_node:
		return

	if body.get("entity_type") == null:
		J.logger.info("Body does not contain entity_type")
		return

	if body.get("position") == null:
		J.logger.info("Body does not contain position")
		return

	if not bodies_in_view.has(body):
		match body.entity_type:
			J.ENTITY_TYPE.PLAYER:
				if body.get("username") == null:
					J.logger.info("Body does not contain username")
					return

				add_player.rpc_id(target_node.peer_id, body.username, body.position)
				player_added.emit(body.username, body.position)
			J.ENTITY_TYPE.ENEMY:
				if body.get("enemy_class") == null:
					J.logger.info("Body does not contain enemy_class")
					return

				add_enemy.rpc_id(target_node.peer_id, body.name, body.enemy_class, body.position)
				enemy_added.emit(body.name, body.enemy_class, body.position)
			J.ENTITY_TYPE.NPC:
				if body.get("npc_class") == null:
					J.logger.info("Body does not contain npc_class")
					return

				add_npc.rpc_id(target_node.peer_id, body.name, body.npc_class, body.position)
				npc_added.emit(body.name, body.npc_class, body.position)

			J.ENTITY_TYPE.ITEM:
				if body.get("item_class") == null:
					J.logger.info("Body does not contain item_class")
					return

				add_item.rpc_id(target_node.peer_id, body.name, body.item_class, body.position)
				item_added.emit(body.name, body.item_class, body.position)

		bodies_in_view.append(body)

		body_entered.emit(body)


func _on_body_network_view_area_body_exited(body: Node2D):
	# Make sure that the player is never removed from the watchers
	if body == target_node:
		return

	if body.get("entity_type") == null:
		J.logger.info("Body does not contain entity_type")
		return

	if bodies_in_view.has(body):
		if target_node.peer_id in multiplayer.get_peers():
			match body.entity_type:
				J.ENTITY_TYPE.PLAYER:
					if body.get("username") == null:
						J.logger.info("Body does not contain username")
						return

					remove_player.rpc_id(target_node.peer_id, body.username)
					player_removed.emit(body.username)
				J.ENTITY_TYPE.ENEMY:
					enemy_removed.emit(body.name)
					remove_enemy.rpc_id(target_node.peer_id, body.name)
				J.ENTITY_TYPE.NPC:
					npc_removed.emit(body.name)
					remove_npc.rpc_id(target_node.peer_id, body.name)
				J.ENTITY_TYPE.ITEM:
					item_removed.emit(body.name)
					remove_item.rpc_id(target_node.peer_id, body.name)

		bodies_in_view.erase(body)

		body_exited.emit(body)


@rpc("call_remote", "authority", "reliable") func add_player(username: String, pos: Vector2):
	player_added.emit(username, pos)


@rpc("call_remote", "authority", "reliable") func remove_player(username: String):
	player_removed.emit(username)


@rpc("call_remote", "authority", "reliable")
func add_enemy(enemy_name: String, enemy_class: String, pos: Vector2):
	enemy_added.emit(enemy_name, enemy_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_enemy(enemy_name: String):
	enemy_removed.emit(enemy_name)


@rpc("call_remote", "authority", "reliable")
func add_npc(npc_name: String, npc_class: String, pos: Vector2):
	npc_added.emit(npc_name, npc_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_npc(npc_name: String):
	npc_removed.emit(npc_name)


@rpc("call_remote", "authority", "reliable")
func add_item(item_uuid: String, item_class: String, pos: Vector2):
	item_added.emit(item_uuid, item_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_item(item_uuid: String):
	item_removed.emit(item_uuid)
